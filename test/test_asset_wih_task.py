import unittest
from app.tasks.asset_wih import AssetWihUpdateTask


class TestWebInfoHunter(unittest.TestCase):
    def test_run_wih_monitor(self):
        scope_id = "64b7d6f47344289cd8abf800"
        task_id = "64bf9a59eff2fe8c8a6172e2"
        task = AssetWihUpdateTask(task_id, scope_id)
        task.run()

