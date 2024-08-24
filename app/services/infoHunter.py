from typing import List
import subprocess
from app import utils
from app.config import Config
import os
import json
from app.modules import WihRecord

logger = utils.get_logger()


class InfoHunter(object):
    # 从JS中收集，子域名，AK SK 等信息
    def __init__(self, sites: list):
        self.sites = set(sites)

        tmp_path = Config.TMP_PATH
        rand_str = utils.random_choices()

        # wih 目标文件
        self.wih_target_path = os.path.join(tmp_path, "wih_target_{}.txt".format(rand_str))

        # wih 结果文件
        self.wih_result_path = os.path.join(tmp_path, "wih_result_{}.json".format(rand_str))

        self.wih_bin_path = "wih"

    def _get_target_file(self):
        with open(self.wih_target_path, "w") as f:
            for site in self.sites:
                f.write(site + "\n")

    def _delete_file(self):
        try:
            os.unlink(self.wih_target_path)
            # 删除结果临时文件
            if os.path.exists(self.wih_result_path):
                os.unlink(self.wih_result_path)
        except Exception as e:
            logger.warning(e)

    def exec_wih(self):
        command = [self.wih_bin_path,
                   "-r {}".format(Config.WIH_RULE_PATH),
                   "-J",
                   "-o {}".format(self.wih_result_path),
                   "--concurrency 3",  # 并发数
                   "--log-level zero",  # 不输出日志
                   "--concurrency-per-site 1",  # 每个站点的并发数
                   "--disable-ak-sk-output",  # 禁止 AK/SK 单独保存
                   "-t {}".format(self.wih_target_path),
                   ]

        if Config.PROXY_URL:
            command.append("--proxy {}".format(Config.PROXY_URL))

        logger.info(" ".join(command))
        utils.exec_system(command, timeout=5 * 24 * 60 * 60)

    def check_have_wih(self) -> bool:
        command = [self.wih_bin_path, "--version"]
        try:
            output = utils.check_output(command, timeout=2 * 60)
            if "version:" in str(output):
                return True
        except Exception as e:
            logger.debug("{}".format(str(e)))

        return False

    def dump_result(self) -> list:
        results = []

        # 检查结果文件是否存在
        if not os.path.exists(self.wih_result_path):
            return results

        with open(self.wih_result_path, "r") as f:
            while True:
                line = f.readline()
                if not line:
                    break

                data = json.loads(line)
                site = data["target"]
                records = data.get("records", [])
                for item in records:
                    content = item["content"]
                    if item["tag"]:
                        content = "{} ({})".format(content, item["tag"])

                    record_dict = {
                        "record_type": item["id"],
                        "content": content,
                        "source": item["source"],
                        "site": site,
                        "fnv_hash": item["hash"],
                    }

                    results.append(WihRecord(**record_dict))

        return results

    def run(self):
        if not self.check_have_wih():
            logger.warning("not found webInfoHunter binary")
            return []

        self._get_target_file()
        self.exec_wih()
        results = self.dump_result()
        self._delete_file()

        return results


def run_wih(sites: List[str]) -> List[WihRecord]:
    logger.info("run webInfoHunter, sites: {}".format(len(sites)))
    hunter = InfoHunter(sites)
    results = hunter.run()

    logger.info("webInfoHunter result: {}".format(len(results)))

    return results
