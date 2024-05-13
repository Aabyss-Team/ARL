import unittest
from app import services
from app.utils import push
from app.config import Config


class TestUtilsPush(unittest.TestCase):
    def __init__(self, *args, **kwargs):
        super(TestUtilsPush, self).__init__(*args, **kwargs)
        self._site_data = None
        self._domain_data = None
        self._ip_data = None

    @property
    def site_data(self):
        if self._site_data is None:
            sites = ["https://www.baidu.com", "https://www.qq.com/"]
            site_data = services.fetch_site(sites, concurrency=2)
            self._site_data = site_data

        return self._site_data

    @property
    def domain_data(self):
        if self._domain_data is None:
            _domain_data = services.build_domain_info(["www.baidu.com", "www.qq.com"])
            domain_data = []
            for x in _domain_data:
                domain_data.append(x.dump_json(flag=False))
            self._domain_data = domain_data

        return self._domain_data

    @property
    def ip_data(self):
        if self._ip_data is None:
            _ip_data = services.build_domain_info(["www.baidu.com", "www.qq.com"])
            ip_data = []
            for x in services.port_scan(["1.1.1.1"]):
                x["geo_asn"] = {
                    "number": 13335,
                    "organization": "Cloudflare, Inc."
                }
                ip_data.append(x)
            self._ip_data = ip_data

        return self._ip_data

    @property
    def domain_asset_map(self):
        asset_map = {
            "site": self.site_data,
            "domain": self.domain_data,
            "task_name": "灯塔测试域名"
        }
        return asset_map

    @property
    def domain_asset_counter(self):
        asset_counter = {
            "site": 10,
            "domain": 10
        }
        return asset_counter

    @property
    def ip_asset_map(self):
        asset_map = {
            "site": self.site_data,
            "ip": self.ip_data,
            "task_name": "灯塔测试 IP"
        }
        return asset_map

    @property
    def ip_asset_counter(self):
        asset_counter = {
            "site": 10,
            "ip": 10
        }
        return asset_counter

    def assert_dingding_config(self):
        self.assertTrue(Config.DINGDING_SECRET)
        self.assertTrue(Config.DINGDING_ACCESS_TOKEN)

    def assert_email_config(self):
        self.assertTrue(Config.EMAIL_PASSWORD)
        self.assertTrue(Config.EMAIL_USERNAME)

    def assert_feishu_config(self):
        self.assertTrue(Config.FEISHU_SECRET)
        self.assertTrue(Config.FEISHU_WEBHOOK)

    def assert_wx_work_config(self):
        self.assertTrue(Config.WX_WORK_WEBHOOK)

    def test_push_dingding(self):
        self.assert_dingding_config()

        push_domain = push.Push(asset_map=self.domain_asset_map, asset_counter=self.domain_asset_counter)
        ret = push_domain.push_dingding()
        self.assertTrue(ret)

        push_ip = push.Push(asset_map=self.ip_asset_map, asset_counter=self.ip_asset_counter)
        ret = push_ip.push_dingding()
        self.assertTrue(ret)

    def test_push_email(self):
        self.assert_email_config()

        push_domain = push.Push(asset_map=self.domain_asset_map, asset_counter=self.domain_asset_counter)
        ret = push_domain.push_email()
        self.assertTrue(ret)

        push_ip = push.Push(asset_map=self.ip_asset_map, asset_counter=self.ip_asset_counter)
        ret = push_ip.push_email()
        self.assertTrue(ret)

    def test_push_feishu(self):
        self.assert_feishu_config()

        push_domain = push.Push(asset_map=self.domain_asset_map, asset_counter=self.domain_asset_counter)
        ret = push_domain.push_feishu()
        self.assertTrue(ret)

        push_ip = push.Push(asset_map=self.ip_asset_map, asset_counter=self.ip_asset_counter)
        ret = push_ip.push_feishu()
        self.assertTrue(ret)

    def test_wx_work_push(self):
        self.assert_wx_work_config()
        push_domain = push.Push(asset_map=self.domain_asset_map, asset_counter=self.domain_asset_counter)
        ret = push_domain.push_wx_work()
        self.assertTrue(ret)

        push_ip = push.Push(asset_map=self.ip_asset_map, asset_counter=self.ip_asset_counter)
        ret = push_ip.push_wx_work()
        self.assertTrue(ret)


if __name__ == '__main__':
    unittest.main()
