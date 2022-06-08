"""
Updates the dnsimple CNAME
"""

import argparse
from typing import List

from dnsimple import Client
from dnsimple.struct import ZoneRecordUpdateInput, ZoneRecordInput, ZoneRecord


def cprint(text, colour):
    """
    Print text with given colour.
    """
    
    c = getattr(Colors, colour.upper())
    print(f'{c}{text}{Colors.END}')


def command_line() -> argparse.Namespace:
    """
    Define and parse the command line args
    """
    parser = argparse.ArgumentParser("Updates a target record with a new target DNS")
    parser.add_argument('access_token', help="DNSimple API Access Token")
    parser.add_argument('zone', help='DNSimple Zone')
    parser.add_argument('target', help='The DNS target for the CNAME')
    parser.add_argument('--name', help='Record name', required=True)
    parser.add_argument('--type', help='Record Type', default='CNAME')
    parser.add_argument('--sandbox', action='store_true', help="Use the sandbox account")
    parser.add_argument('--create', action='store_true', help='Will create a new record if one not found')

    return parser.parse_args()


class Colors:
    """ ANSI color codes """
    BLACK = "\033[0;30m"
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    BROWN = "\033[0;33m"
    BLUE = "\033[0;34m"
    PURPLE = "\033[0;35m"
    CYAN = "\033[0;36m"
    LIGHT_GRAY = "\033[0;37m"
    DARK_GRAY = "\033[1;30m"
    LIGHT_RED = "\033[1;31m"
    LIGHT_GREEN = "\033[1;32m"
    YELLOW = "\033[1;33m"
    LIGHT_BLUE = "\033[1;34m"
    LIGHT_PURPLE = "\033[1;35m"
    LIGHT_CYAN = "\033[1;36m"
    LIGHT_WHITE = "\033[1;37m"
    BOLD = "\033[1m"
    FAINT = "\033[2m"
    ITALIC = "\033[3m"
    UNDERLINE = "\033[4m"
    BLINK = "\033[5m"
    NEGATIVE = "\033[7m"
    CROSSED = "\033[9m"
    END = "\033[0m"
    # cancel SGR codes if we don't write to a terminal
    if not __import__("sys").stdout.isatty():
        for _ in dir():
            if isinstance(_, str) and _[0] != "_":
                locals()[_] = ""
    else:
        # set Windows console in VT mode
        if __import__("platform").system() == "Windows":
            kernel32 = __import__("ctypes").windll.kernel32
            kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
            del kernel32


class DNSimpleClient:

    def __init__(self, access_token, sandbox=False):
        self.client = self.connect(access_token, sandbox)
        self.account_id =  self.client.identity.whoami().data.account.id

    def connect(self, access_token: str, sandbox=False) -> Client:
        """
        Connect to the DNSimple API

        :param args: Command line arguments to initialise the client

        Returns a DNSimple Client
        """

        client_kwargs = {
            "access_token": access_token
        }

        if sandbox:
            client_kwargs["sandbox"]=True

        return Client(**client_kwargs)

    def get_records(self, zone: str, record_type: str, name: str) -> List[ZoneRecord]:
        """
        Get available records given the search params
        """
        return self.client.zones.list_records(
            self.account_id,
            zone, 
            filter={"type": record_type, "name": name}
        )

    def update_record(self, record: str, zone: str, target: str) -> None:
        """
        Update a record
        """

        if record.content == target:
            cprint("CNAME record matches target", colour='green')
        else:
            cprint(f"CNAME record target: {record.content} does not match given target: {target}", colour='red')
            cprint("Updating target...", colour='yellow')
            print(record.__dict__)

            data = ZoneRecordUpdateInput(content=target)

            resp = self.client.zones.update_record(
                self.account_id,
                zone,
                record.id,
                data
            )
            if resp.http_response.status_code in range(200,400):
                cprint("Target updated", colour='green')
            else:
                cprint(resp.http_response, colour='red')

    def create_record(self, name: str, zone: str, target: str, record_type: str, ttl: int = 60) -> None:
        """
        Create a new record
        """
        
        data = ZoneRecordInput(
            name=name,
            type=record_type,
            content=target,
            ttl=ttl
        )

        resp = self.client.zones.create_record(
            self.account_id,
            zone,
            data
        )
        if resp.http_response.status_code in range(200,400):
            cprint('Record created', colour='green')
        else:
            cprint(resp.http_response, colour='red')



    def update_aws_alias(self, target: str, zone: str, record_type: str, name: str, create: bool = False) -> None:

        # Sanitise target
        target = target.strip().replace('"','')

        # Get DNS records
        records = self.get_records(zone, record_type, name)

        if records.data:
            record = records.data[0]
            self.update_record(record, zone, target)
        else:
            cprint(f"No record present in {zone} with type {record_type}", colour='red')

            if create:
                cprint("Creating...", colour='yellow')
                self.create_record(name, zone, target, record_type)

    
if __name__ == "__main__":
    args = command_line()
    client = DNSimpleClient(args.access_token, args.sandbox)
    client.update_aws_alias(args.target, args.zone, args.type, args.name, args.create) 