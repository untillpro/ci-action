echo "argument: $1"

if [ "$#" -ne 1 ]; then
    echo "Please add 1 argument: golangci install folder"
    exit 1	
fi

echo "Install golangci-lint in folder: $1/bin"
#curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.61.0
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.0.2

golangci-lint --version

#echo "Download golangci config"
# curl -o /home/runner/work/.golangci.yaml https://raw.githubusercontent.com/untillpro/ci-action/master/scripts/.golangci.yml

echo "Run linter jobs"
mydir=""
if test -n "$testfolder"; then
  mydir="${testfolder}/..."
fi
$1/bin/golangci-lint run ${mydir} 

status="$?"

if [ ${status} -eq 0 ]; then 
  echo "Skip cyclop"
#  go install github.com/untillpro/cyclop/cmd/cyclop@v1.2.103

#  echo "Run cyclop"
#  $(go env GOPATH)/bin/cyclop -skipSwitch=true -skipTests=true -maxComplexity 12 ./...
else
  exit 1
fi

