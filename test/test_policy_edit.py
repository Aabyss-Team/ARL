import unittest
from app.routes.policy import add_policy_fields, gen_model_policy_keys, change_policy_dict


class TestWebInfoHunter(unittest.TestCase):
    def test_gen_policy_keys(self):
        keys = gen_model_policy_keys(add_policy_fields["policy"])
        self.assertTrue("web_info_hunter" in keys)
        self.assertTrue(len(keys) > 0)

    def test_change_policy_dict(self):
        item = {
            "domain_config": {
                "domain_brute": True,
                "domain_brute_type": "test",
            },
            "ip_config": {
                "port_scan": True,
                "port_scan_type": "top100",
                "service_detection": False,
                "host_timeout": 0,
                "port_parallelism": 32,
                "port_min_rate": 60
            },
            "site_config": {
                "site_identify": False,
                "site_capture": False,
            },
            "file_leak": False,
            "npoc_service_detection": False,
            "scope_config": {
                "scope_id": "643cf62215906b51d3159f9e"
            },
            "poc_config": [],
            "brute_config": []
        }

        item = {
            "name": "test",
            "desc": "old desc",
            "policy": item
        }
        policy_data = {
            "domain_config": {"domain_brute": True, "alt_dns": False, "arl_search": True, "dns_query_plugin": False,
                              "domain_brute_type": "big"},
            "site_config": {
                "site_identify": True,
                "site_capture": True,
                "web_info_hunter": True,
                "not_exist": True,
            }
        }

        policy_data = {
            "name": "update-name",
            "desc": "test",
            "policy": policy_data
        }

        allow_keys = gen_model_policy_keys(add_policy_fields["policy"])
        allow_keys.extend(["name", "desc", "policy"])

        item = change_policy_dict(item, policy_data, allow_keys)

        self.assertTrue(item["name"] == "update-name")
        self.assertTrue(item["desc"] == "test")

        item = item["policy"]

        self.assertTrue(item["site_config"]["site_identify"])
        self.assertTrue(item["site_config"]["web_info_hunter"])
        self.assertTrue(item["ip_config"]["port_scan"])

        self.assertTrue(item["scope_config"]["scope_id"] == "643cf62215906b51d3159f9e")

        self.assertTrue(item["site_config"].get("not_exist") is None)
