from app import utils


def find_private_domain_by_task_id(task_id):
    query = {
        "task_id": task_id,
        "ip_type": "PRIVATE"
    }
    domains = []
    items = utils.conn_db('ip').find(query)
    for item in list(items):
        if not item.get("domain"):
            continue
        domains.extend(item["domain"])

    return list(set(domains))


def find_public_ip_by_task_id(task_id):
    query = {
        "task_id": task_id,
        "ip_type": "PUBLIC"
    }
    items = utils.conn_db('ip').distinct("ip", query)
    return list(items)


def find_domain_by_task_id(task_id):
    query = {
        "task_id": task_id
    }
    items = utils.conn_db('domain').distinct("domain", query)
    return list(items)


