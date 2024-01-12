from abc import ABC, abstractmethod
from typing import Any


class Sender(ABC):
    @abstractmethod
    def prepare_payload(
        self, text: str = "", attachments: list[Any] | None = None
    ) -> None:
        pass

    @abstractmethod
    def send(self):
        pass
