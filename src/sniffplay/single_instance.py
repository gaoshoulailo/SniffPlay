from __future__ import annotations

import hashlib
import json
import logging
import os
from pathlib import Path

from PySide6.QtCore import QObject, QLockFile, Signal
from PySide6.QtNetwork import QLocalServer, QLocalSocket

logger = logging.getLogger(__name__)


class SingleInstanceGuard(QObject):
    activationRequested = Signal(str)

    def __init__(self, data_dir: Path) -> None:
        super().__init__()
        resolved_data_dir = data_dir.resolve()
        identity = hashlib.sha256(
            os.path.normcase(str(resolved_data_dir)).encode("utf-8")
        ).hexdigest()[:16]
        self._server_name = f"sniffplay-{identity}"
        self._lock = QLockFile(str(resolved_data_dir / "sniffplay.lock"))
        self._server: QLocalServer | None = None
        self._buffers: dict[QLocalSocket, bytearray] = {}

    def acquire_or_notify(self, audio_path: Path | None = None) -> bool:
        if not self._lock.tryLock(0):
            self._notify_primary(audio_path)
            return False

        QLocalServer.removeServer(self._server_name)
        server = QLocalServer(self)
        server.setSocketOptions(QLocalServer.SocketOption.UserAccessOption)
        if not server.listen(self._server_name):
            logger.warning(
                "Could not start the single-instance activation server: %s",
                server.errorString(),
            )
            return True

        server.newConnection.connect(self._accept_connections)
        self._server = server
        return True

    def close(self) -> None:
        for socket in tuple(self._buffers):
            socket.abort()
        self._buffers.clear()
        if self._server is not None:
            self._server.close()
            self._server = None
            QLocalServer.removeServer(self._server_name)
        if self._lock.isLocked():
            self._lock.unlock()

    def _notify_primary(self, audio_path: Path | None) -> None:
        socket = QLocalSocket()
        socket.connectToServer(self._server_name)
        if not socket.waitForConnected(1500):
            logger.warning(
                "Another SniffPlay process is running, but it could not be activated"
            )
            return

        payload = json.dumps(
            {"audio_path": str(audio_path) if audio_path is not None else ""},
            ensure_ascii=True,
        ).encode("utf-8") + b"\n"
        socket.write(payload)
        if not socket.waitForBytesWritten(1000):
            logger.warning("Could not send the activation request to SniffPlay")
        socket.disconnectFromServer()
        if socket.state() != QLocalSocket.LocalSocketState.UnconnectedState:
            socket.waitForDisconnected(1000)

    def _accept_connections(self) -> None:
        if self._server is None:
            return
        while self._server.hasPendingConnections():
            socket = self._server.nextPendingConnection()
            if socket is None:
                continue
            self._buffers[socket] = bytearray()
            socket.readyRead.connect(lambda socket=socket: self._read_request(socket))
            socket.disconnected.connect(
                lambda socket=socket: self._discard_socket(socket)
            )
            if socket.bytesAvailable():
                self._read_request(socket)

    def _read_request(self, socket: QLocalSocket) -> None:
        buffer = self._buffers.get(socket)
        if buffer is None:
            return
        buffer.extend(bytes(socket.readAll()))
        if b"\n" not in buffer:
            return

        raw_payload, _, _ = bytes(buffer).partition(b"\n")
        try:
            payload = json.loads(raw_payload.decode("utf-8"))
            audio_path = payload.get("audio_path", "")
            if not isinstance(audio_path, str):
                audio_path = ""
        except (UnicodeDecodeError, json.JSONDecodeError, AttributeError):
            logger.warning("Ignored an invalid single-instance activation request")
            audio_path = ""

        self.activationRequested.emit(audio_path)
        socket.disconnectFromServer()

    def _discard_socket(self, socket: QLocalSocket) -> None:
        self._buffers.pop(socket, None)
        socket.deleteLater()
