from abc import ABC, abstractmethod
from typing import Any, List, Optional


class Sender(ABC):
    @abstractmethod
    def prepare_payload(
        self, text: str = "", attachments: Optional[List[Any]] = None
    ) -> None:
        pass

    @abstractmethod
    def send(self):
        pass
