#!/bin/bash

# Run the unit tests against different versions of dockerized mysql servers
# and python versions

if [ ! -f .env ]; then
    echo 'Missing .env file'
    exit 1
fi

# Download database fixtures
./download-db-fixtures.sh || exit 1

echo 'Building images...'
FILE=docker-compose-tests.yml
docker-compose -f $FILE build
docker-compose -f $FILE up -d

# Wait for all mysql containers to finish initialization
sleep 5
for version in mysql56 mysql57 mysql8; do
    name=$(docker-compose -f $FILE ps -q $version)
    status=$(docker inspect --format='{{.State.Health}}' $name | grep -o healthy)

    while [ "$status" != "healthy" ]; do
        status=$(docker inspect --format='{{.State.Health}}' $name | grep -o healthy)
        echo "$version server status is: $status"
        sleep 1
    done
done

echo 'All done! Running tests...'

{
    echo "py36 - mysql56"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql56' python36 tox -- -x || exit 1
    echo "py36 - mysql57"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql57' python36 tox -- -x || exit 1
    echo "py36 - mysql8"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql8' python36 tox -- -x || exit 1

    echo "py37 - mysql56"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql56' python37 tox -- -x || exit 1
    echo "py37 - mysql57"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql57' python37 tox -- -x || exit 1
    echo "py37 - mysql8"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql8' python37 tox -- -x || exit 1

    echo "py38 - mysql56"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql56' python38 tox -- -x || exit 1
    echo "py38 - mysql57"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql57' python38 tox -- -x || exit 1
    echo "py38 - mysql8"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql8' python38 tox -- -x || exit 1

    echo "py39 - mysql56"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql56' python39 tox -- -x || exit 1
    echo "py39 - mysql57"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql57' python39 tox -- -x || exit 1
    echo "py39 - mysql8"
    docker-compose -f $FILE run --rm -e DB_HOST='tcp://mysql8' python39 tox -- -x || exit 1
} > tests.log 2>&1

cat tests.log

docker-compose -f $FILE stop
