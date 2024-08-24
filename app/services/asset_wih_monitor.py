from app.helpers import asset_site, asset_wih, get_scope_by_scope_id
from app.services import run_wih
from app.utils import get_logger, check_domain_black
from app.modules import WihRecord
from app import utils

logger = get_logger()


class AssetWihMonitor(object):
    def __init__(self, scope_id: str):
        self.scope_id = scope_id
        self.scope_domains = []  # 资产分组中的域名范围
        self.scope_name = None  # 资产分组名称
        self.sites = []
        self._wih_record_fnv_hash = None

    def init_scope_data(self):
        scope_data = get_scope_by_scope_id(self.scope_id)
        if not scope_data:
            raise Exception("没有找到资产组 {}".format(self.scope_id))

        self.scope_name = scope_data.get("name", "")
        scope_type = scope_data.get("scope_type", "")

        if scope_type == "domain":
            self.scope_domains = scope_data.get("scope_array", [])

        self.sites = asset_site.find_site_by_scope_id(self.scope_id)

    def have_asset_wih_record(self, record: WihRecord) -> bool:
        """
        检查数据库中是否已经存在记录
        :param record:
        :return:
        """

        query = {"scope_id": self.scope_id, "fnv_hash": str(record.fnv_hash)}
        item = utils.conn_db('asset_wih').find_one(query)
        if item:
            return True
        return False

    def save_asset_wih_record(self, record: WihRecord):
        """
        保存到数据库
        :param record: 
        :return: 
        """

        if self.have_asset_wih_record(record):
            return

        item = record.dump_json()

        item["scope_id"] = self.scope_id
        curr_date = utils.curr_date_obj()
        item["save_date"] = curr_date
        item["update_date"] = curr_date
        utils.conn_db('asset_wih').insert_one(item)

    @property
    def wih_record_fnv_hash(self):
        if self._wih_record_fnv_hash is None:
            self._wih_record_fnv_hash = asset_wih.get_wih_record_fnv_hash(self.scope_id)
        return self._wih_record_fnv_hash

    def run(self):
        results = []
        self.init_scope_data()

        logger.info("run AssetWihMonitor, scope_id: {} sites: {}".format(self.scope_id, len(self.sites)))

        if len(self.sites) == 0:
            return results

        wih_results = run_wih(self.sites)

        fnv_hash_set = set(self.wih_record_fnv_hash)
        for item in wih_results:

            # 保存到数据库的是字符串，所以这里要转换一下
            item_fnv_hash = str(item.fnv_hash)

            # 如果已经存在，就跳过
            if item_fnv_hash in fnv_hash_set:
                continue

            if item.recordType == "domain":
                if self.scope_domains:
                    if not domain_in_scope_domain(item.content, self.scope_domains):
                        continue

                # 表示域名在黑名单中
                if check_domain_black(item.content):
                    continue

            # 保存到数据库
            self.save_asset_wih_record(item)

            results.append(item)
            fnv_hash_set.add(item_fnv_hash)

        logger.info("AssetWihMonitor, scope_id: {} results: {}".format(self.scope_id, len(results)))

        # 后面这个用不到了，清空，省内存
        self._wih_record_fnv_hash = None

        return results


def asset_wih_monitor(scope_id: str):
    monitor = AssetWihMonitor(scope_id)
    results = monitor.run()
    return results


def domain_in_scope_domain(domain: str, scope_domain: list):
    for scope in scope_domain:
        if domain.endswith("." + scope):
            return True
    return False
