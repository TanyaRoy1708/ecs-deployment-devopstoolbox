import ipaddress

def calculate_cidr(cidr_str: str) -> dict:
    try:
        network = ipaddress.IPv4Network(cidr_str, strict=False)
        return {
            "success": True,
            "network_address": str(network.network_address),
            "broadcast_address": str(network.broadcast_address),
            "netmask": str(network.netmask),
            "num_hosts": network.num_addresses - 2 if network.prefixlen < 31 else network.num_addresses,
            "first_host": str(list(network.hosts())[0]) if network.num_addresses > 2 else "N/A",
            "last_host": str(list(network.hosts())[-1]) if network.num_addresses > 2 else "N/A"
        }
    except Exception as e:
        return {"success": False, "error": str(e)}
