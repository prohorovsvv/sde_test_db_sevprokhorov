#!/bin/bash
cp ../sql/init_db/demo.sql ../bash/
docker pull postgres
docker run --rm --name demo \
  -e POSTGRES_PASSWORD="@sde_password012" \
  -e POSTGRES_USER="test_sde" \
  -e POSTGRES_DB="demo" -d -p 5450:5432 \
  -v $(pwd):/var/lib/postgres/sql/ postgres
sleep 5
docker exec -it demo psql -U test_sde -d demo -f /var/lib/postgres/sql/demo.sql
rm demo.sql
