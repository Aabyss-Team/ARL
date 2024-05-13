from .baseInfo import BaseInfo

class PageInfo(BaseInfo):
    def __init__(self, title, url, content_length, status_code):
        self.title = title
        self.url = url
        self.content_length = content_length
        self.status_code = status_code

    def __eq__(self, other):
        if isinstance(other, PageInfo):
            if self.url == other.url:
                return True

    def __hash__(self):
        return hash(self.url)

    def _dump_json(self):
        item = {
            "title": self.title,
            "url": self.url,
            "content_length": self.content_length,
            "status_code": self.status_code
        }
        return item