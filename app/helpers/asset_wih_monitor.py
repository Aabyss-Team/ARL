from app.modules import TaskStatus, TaskType


def submit_asset_wih_monitor_job(scope_id, name, scheduler_id):
    from app.helpers.task import submit_task

    task_data = {
        'name': name,
        'target': "资产分组 WIH 更新",
        'start_time': '-',
        'status': TaskStatus.WAITING,
        'type':  TaskType.ASSET_WIH_UPDATE,
        "task_tag": TaskType.ASSET_WIH_UPDATE,
        'options': {
            "scope_id": scope_id,
            "scheduler_id": scheduler_id
        },
        "end_time": "-",
        "service": [],
        "celery_id": ""
    }

    submit_task(task_data)