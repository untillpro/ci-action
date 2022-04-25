echo "argument: $1"

if [ "$#" -ne 1 ]; then
    echo "Please add 1 argument: golangci install folder"
    exit 1	
fi

echo "Install golangci-lint in folder: $1/bin"
curl -sfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh| sh -s -- -b $1/bin v1.45.2

echo "Download golangci config"
curl -s https://raw.githubusercontent.com/untillpro/ci-action/master/scripts/.golangci.yml > /home/runner/work/.golangci.yaml

echo "Run linter jobs"
$1/bin/golangci-lint run --config /home/runner/work/.golangci.yaml -v

status="$?"

if [ ${status} -eq 0 ]; then 
  echo "Install cyclop"
  go install github.com/untillpro/cyclop/cmd/cyclop@v1.2.101

  echo "Run cyclop"
  $(go env GOPATH)/bin/cyclop -skipSwitch=true -skipTests=true -maxComplexity 12 ./.
else
	exit 1
fi
