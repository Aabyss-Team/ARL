# ARL Docker Setup Guide

## Successfully Running ARL in Docker

The ARL (Asset Reconnaissance Lighthouse) project is now running in Docker containers.

### What Was Fixed

1. **Updated Docker Images**: Changed from the removed `tophant/arl` repository to the maintained `honmashironeko/arl-docker-all:latest` image
2. **Fixed Base Images**: Updated MongoDB to `mongo:4.0` and RabbitMQ to `rabbitmq:3.13-management-alpine`
3. **Fixed Log Files**: Resolved log file mounting issues by creating proper files instead of directories
4. **Removed Obsolete Config**: Removed the deprecated `version` field from docker-compose.yml

### Current Status

All containers are running successfully:
- ✅ `arl_web` - Web interface (HTTPS on port 5003)
- ✅ `arl_worker` - Background task worker
- ✅ `arl_scheduler` - Task scheduler
- ✅ `arl_mongodb` - MongoDB database
- ✅ `arl_rabbitmq` - RabbitMQ message broker

### Access Information

**Web Interface**: `https://localhost:5003/`

**Default Credentials** (according to project documentation):
- Username: `admin`
- Password: `honmashironeko` (for this Docker image)

Alternative credentials may be:
- Username: `admin`
- Password: `arlpass` (original default)

### Managing the Containers

**Start containers:**
```bash
cd /home/rifat/projects/python/ARL/docker
docker-compose up -d
```

**Stop containers:**
```bash
cd /home/rifat/projects/python/ARL/docker
docker-compose down
```

**View logs:**
```bash
docker logs arl_web
docker logs arl_worker
docker logs arl_scheduler
```

**Check container status:**
```bash
docker-compose ps
```

**Restart a specific service:**
```bash
docker-compose restart web
```

### Data Persistence

- MongoDB data is stored in the `arl_db` Docker volume
- Logs are stored in `arl_web.log` and `arl_worker.log`
- Screenshots are stored in the `image/` directory
- Custom PoCs can be added to the `poc/` directory

### Password Reset

If you forget the password, run:
```bash
docker exec -ti arl_mongodb mongo -u admin -p admin
use arl
db.user.drop()
db.user.insert({ username: 'admin', password: hex_md5('arlsalt!@#'+'admin123') })
```

Then login with `admin` / `admin123`

### Configuration

Edit `docker/config-docker.yaml` to configure:
- External API keys (FOFA, Hunter, etc.)
- Message notifications (DingDing, Email, Feishu)
- Proxy settings
- Custom dictionaries and ports

After changing configuration, restart the containers:
```bash
docker-compose restart
```

### Troubleshooting

1. **Containers won't start**: Check logs with `docker logs <container_name>`
2. **Port 5003 already in use**: Change the port mapping in docker-compose.yml
3. **Permission issues**: Ensure Docker has proper permissions or use sudo

### Next Steps

1. Access the web interface at https://localhost:5003/
2. Login with the default credentials
3. Change the default password immediately
4. Configure API keys for domain reconnaissance plugins
5. Start your first asset reconnaissance task

For more information, see the main [README.md](README.md)
