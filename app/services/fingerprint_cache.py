from .fingerprint import FingerPrint
from app.utils import get_logger, conn_db

logger = get_logger()


# 用于缓存指纹数据，避免每次请求都从MongoDB中获取数据
class FingerPrintCache:
    def __init__(self):
        self.cache = None

    def is_cache_valid(self):
        return self.cache is not None

    def get_data(self):
        if self.is_cache_valid():
            return self.cache

        # 如果缓存无效，则重新从MongoDB中获取数据
        self.cache = self.fetch_data_from_mongodb()
        return self.cache

    def fetch_data_from_mongodb(self) -> [FingerPrint]:
        items = list(conn_db('fingerprint').find())
        finger_list = []
        for rule in items:
            finger = FingerPrint(rule['name'], rule['human_rule'])
            finger_list.append(finger)

        return finger_list

    def update_cache(self):
        # 手动更新缓存
        self.cache = self.fetch_data_from_mongodb()


finger_db_cache = FingerPrintCache()


def finger_db_identify(variables: dict) -> [str]:
    finger_list = finger_db_cache.get_data()
    finger_name_list = []

    for finger in finger_list:
        try:
            if finger.identify(variables):
                finger_name_list.append(finger.app_name)
        except Exception as e:
            logger.warning("error on identify {} {}".format(finger.app_name, e))

    return finger_name_list


def have_human_rule_from_db(rule: str) -> bool:
    query = {
        "human_rule": rule,
    }

    if conn_db('fingerprint').find_one(query):
        return True
    else:
        return False

