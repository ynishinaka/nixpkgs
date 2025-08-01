# This file contains type hints that can be prepended to Nix test scripts so they can be type
# checked.

from test_driver.debug import DebugAbstract
from test_driver.driver import Driver
from test_driver.vlan import VLan
from test_driver.machine import Machine
from test_driver.logger import AbstractLogger
from typing import Callable, Iterator, ContextManager, Optional, List, Dict, Any, Union
from typing_extensions import Protocol
from pathlib import Path
from unittest import TestCase


class RetryProtocol(Protocol):
    def __call__(self, fn: Callable, timeout: int = 900) -> None:
        raise Exception("This is just type information for the Nix test driver")


class PollingConditionProtocol(Protocol):
    def __call__(
        self,
        fun_: Optional[Callable] = None,
        *,
        seconds_interval: float = 2.0,
        description: Optional[str] = None,
    ) -> Union[Callable[[Callable], ContextManager], ContextManager]:
        raise Exception("This is just type information for the Nix test driver")


class CreateMachineProtocol(Protocol):
    def __call__(
        self,
        start_command: str | dict,
        *,
        name: Optional[str] = None,
        keep_vm_state: bool = False,
    ) -> Machine:
        raise Exception("This is just type information for the Nix test driver")


start_all: Callable[[], None]
subtest: Callable[[str], ContextManager[None]]
retry: RetryProtocol
test_script: Callable[[], None]
machines: List[Machine]
vlans: List[VLan]
driver: Driver
log: AbstractLogger
create_machine: CreateMachineProtocol
run_tests: Callable[[], None]
join_all: Callable[[], None]
serial_stdout_off: Callable[[], None]
serial_stdout_on: Callable[[], None]
polling_condition: PollingConditionProtocol
debug: DebugAbstract
t: TestCase
