from bson import ObjectId
from flask_restx import Resource, Api, reqparse, fields, Namespace
from app.utils import get_logger, auth
from app import utils
from app.modules import ErrorMsg
from . import base_query_fields, ARLResource, get_arl_parser

ns = Namespace('ip', description="IP信息")

logger = get_logger()

base_search_fields = {
    'ip': fields.String(required=False, description="IP"),
    'domain': fields.String(description="域名"),
    'port_info.port_id': fields.Integer(description="端口号"),
    'port_info.service_name': fields.String(description="系统服务名称"),
    'port_info.version': fields.String(description="系统服务版本"),
    'port_info.product': fields.String(description="产品"),
    'os_info.name': fields.String(description="操作系统名称"),
    "task_id": fields.String(description="任务ID"),
    "ip_type": fields.String(description="IP类型，公网(PUBLIC)和内网(PRIVATE)"),
    "cdn_name": fields.String(description="CDN 厂商名称"),
    "geo_asn.number": fields.Integer(description="AS number"),
    "geo_asn.organization": fields.String(description="AS organization"),
    "geo_city.region_name": fields.String(description="GEO region_name")
}

base_search_fields.update(base_query_fields)


@ns.route('/')
class ARLIP(ARLResource):
    parser = get_arl_parser(base_search_fields, location='args')

    @auth
    @ns.expect(parser)
    def get(self):
        """
        IP信息查询
        """
        args = self.parser.parse_args()
        data = self.build_data(args=args, collection='ip')

        return data


@ns.route('/export/')
class ARLIPExport(ARLResource):
    parser = get_arl_parser(base_search_fields, location='args')

    @auth
    @ns.expect(parser)
    def get(self):
        """
        端口导出
        """
        args = self.parser.parse_args()
        response = self.send_export_file(args=args, _type="ip")

        return response


@ns.route('/export_domain/')
class ARLIPExportDomain(ARLResource):
    parser = get_arl_parser(base_search_fields, location='args')

    @auth
    @ns.expect(parser)
    def get(self):
        """
        从 IP 中导出域名
        """
        args = self.parser.parse_args()
        response = self.send_export_file_attr(args=args, collection="ip", field="domain")

        return response


@ns.route('/export_ip/')
class ARLIPExportIp(ARLResource):
    parser = get_arl_parser(base_search_fields, location='args')

    @auth
    @ns.expect(parser)
    def get(self):
        """
        从 IP 中导出 IP
        """
        args = self.parser.parse_args()
        response = self.send_export_file_attr(args=args, collection="ip", field="ip")

        return response


delete_ip_fields = ns.model('deleteIpFields',  {
    '_id': fields.List(fields.String(required=True, description="IP _id"))
})


@ns.route('/delete/')
class DeleteARLIP(ARLResource):
    @auth
    @ns.expect(delete_ip_fields)
    def post(self):
        """
        删除 IP
        """
        args = self.parse_args(delete_ip_fields)
        id_list = args.pop('_id', [])
        for _id in id_list:
            query = {'_id': ObjectId(_id)}
            utils.conn_db('ip').delete_one(query)

        return utils.build_ret(ErrorMsg.Success, {'_id': id_list})
