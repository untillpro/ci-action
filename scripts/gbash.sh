echo "argument: $1"

if [ "$#" -ne 1 ]; then
    echo "Please add 1 argument: golangci install folder"
    exit 1	
fi

echo "Install golangci-lint in folder: $1/bin"
curl -sfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh| sh -s -- -b $1/bin v1.43.0

echo "Download golangci config"
curl -s https://raw.githubusercontent.com/untillpro/ci-action/master/scripts/.golangci.yml > /home/runner/work/.golangci.yml

echo "Run linter jobs"
$1/bin/golangci-lint run        



