import time
from app.services import build_domain_info,\
    probe_http, fetch_site, BaseUpdateTask

from app.helpers import find_domain_by_task_id

from app import utils


logger = utils.get_logger()


class DomainSiteUpdate(object):
    def __init__(self, task_id: str, domains: list, source: str):
        self.task_id = task_id
        self.domains = domains
        self.source = source
        self.domain_info_list = []
        self.available_sites = []
        self.base_update_task = BaseUpdateTask(self.task_id)

    def save_domain_info(self):
        domain_info_list = build_domain_info(self.domains)
        for domain_info_obj in domain_info_list:
            domain_info = domain_info_obj.dump_json(flag=False)
            domain_info["task_id"] = self.task_id
            domain_info["source"] = self.source
            domain_parsed = utils.domain_parsed(domain_info["domain"])
            if domain_parsed:
                domain_info["fld"] = domain_parsed["fld"]
            utils.conn_db('domain').insert_one(domain_info)

        self.domain_info_list = domain_info_list

    def probe_sites(self):
        available_domains = []
        for domain_info_obj in self.domain_info_list:
            available_domains.append(domain_info_obj.domain)

        self.available_sites = probe_http(available_domains, 15)

    def save_site_info(self):
        site_info_list = fetch_site(self.available_sites)

        for site_info in site_info_list:
            curr_site = site_info["site"]
            site_path = "/image/" + self.task_id
            file_name = '{}/{}.jpg'.format(site_path, utils.gen_filename(curr_site))
            site_info["task_id"] = self.task_id
            site_info["screenshot"] = file_name

        if site_info_list:
            utils.conn_db('site').insert_many(site_info_list)

    # 对域名进行检查，如果域名不在任务范围内，就不进行更新
    def set_and_check_domains(self):
        task_domains = find_domain_by_task_id(self.task_id)
        self.domains = list(set(self.domains) - set(task_domains))

    def run(self):
        status_name = f"{self.source}_domain_update"

        self.set_and_check_domains()

        logger.info("start domain site update task_id: {}, len:{}, source: {}".format(self.task_id,
                                                                                      len(self.domains), self.source))
        self.base_update_task.update_task_field("status", status_name)

        t1 = time.time()
        self.save_domain_info()
        self.probe_sites()
        self.save_site_info()
        elapse = time.time() - t1

        self.base_update_task.update_services(status_name, elapse)

        logger.info("end domain site update elapse {}".format(elapse))


# 将域名直接加到任务数据中，只加到域名和站点表中，
# 没有检验添加的域名是否在任务范围中
# 会检验域名是否已经存在任务中
def domain_site_update(task_id: str, domains: list, source: str):
    DomainSiteUpdate(task_id, domains, source).run()