from app import utils


def get_wih_record_fnv_hash(scope_id):
    query = {
        "scope_id": scope_id
    }
    items = utils.conn_db('asset_wih').distinct("fnv_hash", query)
    return list(items)