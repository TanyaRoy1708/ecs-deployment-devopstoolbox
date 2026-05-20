import ipaddress

def calculate_cidr(cidr_str: str) -> dict:
    try:
        network = ipaddress.IPv4Network(cidr_str, strict=False)
        prefix = network.prefixlen
        
        if prefix == 32:
            first_host = str(network.network_address)
            last_host = str(network.network_address)
            num_hosts = 1
        elif prefix == 31:
            first_host = str(network.network_address)
            last_host = str(network.broadcast_address)
            num_hosts = 2
        else:
            first_host = str(network.network_address + 1)
            last_host = str(network.broadcast_address - 1)
            num_hosts = network.num_addresses - 2

        return {
            "success": True,
            "network_address": str(network.network_address),
            "broadcast_address": str(network.broadcast_address),
            "netmask": str(network.netmask),
            "num_hosts": num_hosts,
            "first_host": first_host,
            "last_host": last_host
        }
    except Exception as e:
        return {"success": False, "error": str(e)}
