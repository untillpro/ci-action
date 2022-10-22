#!/bin/bash

dorepo () {
  reponame=${1%%[[:cntrl:]]}
  fullrepname="https://$reponame"
  repover=${2%%[[:cntrl:]]}
  actiontype=${3}

  searchstring=' ' 
  rcprefix='_rc'
   
  rc='rc'

  origreponame=$reponame
  s='-'
  p=' '
  pnt='.'
  sl='/'

   repover=${repover#*$s}

   prefixversion=""	
   version=${repover%$s*}
   version=${version#*$s}
   if [[ $version == *$pnt* ]]; then
     prefixversion=${version%$pnt*}
   fi

   for i in {1..5}; do	 
     reponame=${reponame%$searchstring*}
   done
   orgname=${reponame%$sl*} 
   orgname=${orgname#*$sl}

   purereponame=${reponame##*/}

   retrepo="$(gh repo list untillpro -L 400 --public | awk '{print $1}' |sed 's/${orgname}\///' | grep -o $purereponame | head -n 1 )"
   if [[ $retrepo == $purereponame ]];then
	# the repo is public and not needed to go to RC
	return
   fi
   
   dirname="$purereponame$rcprefix" 
   brexi=0
   if [[ $actiontype != "new" ]];then
     brexi="$(git ls-remote --heads $fullrepname $rc | wc -l)"
   fi
   if [ $brexi -eq 0 ]
   then
     # rc branch does not exist for repo, need to create it
     echo "Branch RC for $reponame does not exist yet. Creating from alpha..."
     git clone $fullrepname $dirname
     mainbranch="$(git remote show $fullrepname | sed -n '/HEAD branch/s/.*: //p')"	
     mainbranch=${mainbranch%%[[:cntrl:]]}
     cd $dirname

     # delete existing rc branch - not needed old one
     git push origin :$rc

     # set upstream to parent heeus repo 
     git remote add upstream $fullrepname

     # get last code from upstream
     git pull -p upstream $mainbranch

     # create devbranch with topic number
     git checkout -b $rc
    
     # get last from newbranch
     git pull -p -r origin $rc
    
     # push to newbranch
     git push -u origin $rc
   else
     if [ -d ${dirname} ]; then	
       cd $dirname
       git pull
     else
       git clone -b $rc $fullrepname $dirname
       cd $dirname
     fi 
   fi 

   lastcommitrc=$(git ls-remote $fullrepname heads/rc)
   lcommitrc=${lastcommitrc:0:12}
   lastdtrawrc=$(git show -s --format=%ci ${lcommitrc})

   lastcommitmain=$(git ls-remote $fullrepname heads/main)
   lcommitmain=${lastcommitmain:0:12}
   lastdtrawmain=$(git show -s --format=%ci ${lcommitmain})

   if [[ "$lastdtrawmain" > "$lastdtrawrc" ]] 
   then
     cp ../fix_gomod.sh fix_gomod.sh
     sh fix_gomod.sh
     git pull
     rm fix_gomod.sh 
     go mod tidy

     # commit updated go mod
     git add .	
     git commit -m "Update go.mod to RC with new dependency versions"
     git push 
   fi
   # Get last commit from branch RC

   lastcommit=$(git ls-remote $fullrepname heads/rc)
   lcommit=${lastcommit:0:12}
   lastdtraw=$(git show -s --format=%ci ${lcommit})
   space=" "
   tshift=${lastdtraw#*$space}
   tshift=${tshift#*$space}

   sign=${tshift:0:1}
   hh=${tshift:1:2}
   mm=${tshift:3:2}

   lastdt="${lastdtraw:0:4}-${lastdtraw:5:2}-${lastdtraw:8:2} ${lastdtraw:11:2}:${lastdtraw:14:2}:${lastdtraw:17:2}"
   ago=""   
   if [[ $sign == "+" ]];then
     ago="ago"
   fi
   dt=$(date -d "$lastdt ${hh} hour $ago" '+%F %T')
   dt=$(date -d "$dt ${mm} min $ago" '+%F %T')
   newdt="${dt:0:4}${dt:5:2}${dt:8:2}${dt:11:2}${dt:14:2}${dt:17:2}"
   if [ ! -z "$prefixversion" ]; then
	newdt="${prefixversion}.${newdt}"     
   fi

   newver="${newdt}-${lcommit}"
   newver=${newver%%[[:cntrl:]]}
 
   cd ..
   rm -r $dirname

   if [[ $repover == $newver ]]; then 
     echo "Dependency $fullrepname did not change in RC"
   else
     fname="go.mod"
     # replace dependency version in go.mod file
     sed -i "s/${repover}/${newver}/" $fname
   fi 
}

# get list of all heeus/untillpro repos,  which go.mod depends on
require="require"
while read line
do
  if [[ ! -z $line ]]
  then 
    if [[ $line == *"untillpro"* ]] || [[ $line == *"heeus"* ]]; then
      if [[ $line != *"module"* ]]; then                                                                                             
  	repoline=$(sed "s/$require//g" <<< "$line")	
        repoline="${repoline%%[[:cntrl:]]}"
 	dorepo $repoline $1
      fi
    fi	
  fi	
done < go.mod

read -p "Press [Enter] to complete RC"

