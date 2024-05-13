import unittest
from app.helpers.asset_wih_monitor import submit_asset_wih_monitor_job
from app.tasks import asset_wih_update_task
from app.services.asset_wih_monitor import asset_wih_monitor


class TestAssetWihMonitor(unittest.TestCase):
    def test_run_wih_monitor(self):
        scope_id = "64b7d6f47344289cd8abf800"
        results = asset_wih_monitor(scope_id)

        for result in results:
            print(result)

        self.assertTrue(len(results) > 2)

    def test_monitor_job(self):
        submit_asset_wih_monitor_job(scope_id="64b7d6f47344289cd8abf800",
                                     name="测试WIH监控", scheduler_id="6461eb28afa20f493f5be7e9")

    def test_asset_wih_update_task(self):
        asset_wih_update_task(
            task_id="64c254f26c425108fb1a4821",
            scope_id="64b7d6f47344289cd8abf800",
            scheduler_id="6461eb28afa20f493f5be7e9"
                              )