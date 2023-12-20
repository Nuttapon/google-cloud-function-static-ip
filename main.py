import requests # type: ignore
import functions_framework  # type: ignore
from typing import Any

@functions_framework.http
def test_ip(request) -> Any:
    result = requests.get("https://api.ipify.org?format=json")
    return result.json()

def test_ip_2(request) -> Any:
    result = requests.get("https://api.ipify.org?format=json")
    return result.json()
