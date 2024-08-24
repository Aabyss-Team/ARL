from bson import ObjectId
from app import utils


# 用于更新任务状态
class BaseUpdateTask(object):
    def __init__(self, task_id: str):
        self.task_id = task_id

    def update_services(self, service_name: str, elapsed: float):
        elapsed = "{:.2f}".format(elapsed)
        self.update_task_field("status", service_name)
        query = {"_id": ObjectId(self.task_id)}
        update = {"$push": {"service": {"name": service_name, "elapsed": float(elapsed)}}}
        utils.conn_db('task').update_one(query, update)

    def update_task_field(self, field=None, value=None):
        query = {"_id": ObjectId(self.task_id)}
        update = {"$set": {field: value}}
        utils.conn_db('task').update_one(query, update)