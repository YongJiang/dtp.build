# User specific environment and startup programs
umask 002

BASE_PATH=.:/bin:/usr/bin:/usr/bin/X11:/usr/local/bin:/usr/bin:/usr/X11R6/bin
LD_LIBRARY_PATH=.
BASH_ENV=$HOME/.bashrc
USERNAME=`whoami`
xhost +$HOSTNAME
DISPLAY=:0.0
export DISPLAY USERNAME BASH_ENV LD_LIBRARY_PATH

ulimit -c unlimited


#Below variables deed to be updated
export GitRepo=ssh://xgu@git.eclipse.org/gitroot/datatools
export BranchName=master

postingDirectory=$HOME/releng/BIRTOutput/dtp.output/1.10.0

bootclasspath_15="/usr/local/jdk1.5.0_02/jre/lib/rt.jar:/usr/local/jdk1.5.0_02/jre/lib/jce.jar"
bootclasspath_16="/usr/local/jdk1.6.0/jre/lib/rt.jar:/usr/local/jdk1.6.0/jre/lib/jsse.jar"
jvm15_home="/usr/local/jdk1.5.0_02"
jvm16_home="/usr/local/jdk1.6.0"
###################################

#if [ "x"$ANT_HOME = "x" ]; then export ANT_HOME=/usr/local/apache-ant-1.7.0; fi
#if [ "x"$JAVA_HOME = "x" ]; then export JAVA_HOME=/usr/local/j2sdk1.4.2_13; fi
#export PATH=${PATH}:${ANT_HOME}/bin:/usr/local/bin

proc=$$

#notification list
recipients=yjiang@actuate.com,xgu@actuate.com
sender=qa-build@actuate.com

#sets skip.performance.tests Ant property
skipPerf=""

#sets skip.tests Ant property
skipTest=""

#sets sign Ant property
sign=""

tagMaps=""

#sets fetchTag="HEAD" for nightly builds if required
tag=""

#buildProjectTags=v20060524
buildProjectTags=v20060529

#updateSite property setting
updateSite=""

#flag indicating whether or not mail should be sent to indicate build has started
mail=""

#flag used to build based on changes in map files
compareMaps=""

#buildId - build name
buildId=""

#buildLabel - name parsed in php scripts <buildType>-<buildId>-<datestamp>
buildLabel=""

# tag for build contribution project containing .map files
mapVersionTag=HEAD

# directory in which to export builder projects
builderDir=$HOME/releng.dtp.1100/org.eclipse.datatools.releng.builder

# buildtype determines whether map file tags are used as entered or are replaced with HEAD
buildType=I

# flag to indicate if test build
testBuild=""

# path to javadoc executable
javadoc=""

# value used in buildLabel and for text replacement in index.php template file
builddate=`date +%Y%m%d`
buildtime=`date +%H%M`

buildinfoDate=`date +%F%t%H:%M:%S`
buildinfounivDate=`date +%c%z`

timestamp=$builddate$buildtime

echo "======[builddate]: $builddate " > $USER.log
echo "======[buildtime]: $buildtime " >> $USER.log
echo "======[timestamp]: $timestamp " >> $USER.log

# process command line arguments
usage="usage: $0 [-notify emailaddresses][-test][-buildDirectory directory][-buildId name][-buildLabel directory name][-tagMapFiles][-mapVersionTag tag][-builderTag tag][-bootclasspath path][-compareMaps][-skipPerf] [-skipTest][-updateSite site][-sign] M|N|I|S|R"

if [ $# -lt 1 ]
then
		 echo >&2 "$usage"
		 exit 1
fi

while [ $# -gt 0 ]
do
		 case "$1" in
		 		 -buildId) buildId="$2"; shift;;
		 		 -buildLabel) buildLabel="$2"; shift;;
		 		 -mapVersionTag) mapVersionTag="$2"; shift;;
				 -noAutoTag) noAutoTag=true;;
				 -ForceAutoTag) ForceAutoTag=true;;
		 		 -tagMapFiles) tagMaps="-DtagMaps=true";;
		 		 -noSign) noSign="-DnoSign=true";;
		 		 -skipPerf) skipPerf="-Dskip.performance.tests=true";;
		 		 -skipTest) skipTest="-Dskip.tests=true";;
		 		 -buildDirectory) builderDir="$2"; shift;;
		 		 -notify) recipients="$2"; shift;;
		 		 -test) postingDirectory="/builds/transfer/files/bogus/downloads/drops";testBuild="-Dtest=true";;
		 		 -builderTag) buildProjectTags="$2"; shift;;
		 		 -compareMaps) compareMaps="-DcompareMaps=true";;
		 		 -updateSite) updateSite="-DupdateSite=$2";shift;;
		 		 -sign) sign="-Dsign=true";shift;;
                                 -upload) upload=true;;
				 -CheckPluginVersion) CheckPluginVersion=true;;
		 		 -*)
		 		 		 echo >&2 $usage
		 		 		 exit 1;;
		 		 *) break;;		 # terminate while loop
		 esac
		 shift
done

# After the above the build type is left in $1.
buildType=$1
echo "======[buildType]: $buildType " >> $USER.log

# Set default buildId and buildLabel if none explicitly set
if [ "$buildId" = "" ]
then
		 #buildId=$buildType$builddate-$buildtime
		 buildId=v$builddate-$buildtime
fi

if [ "$buildLabel" = "" ]
then
		 buildLabel=$buildId
fi
echo "======[buildId]: $buildId " >> $USER.log

#Set the tag to HEAD for Nightly builds
if [ "$buildType" = "N" ]
then
        tag="-DfetchTag=CVS=HEAD,GIT=master"
        versionQualifier="-DforceContextQualifier=$buildId"
fi

echo "======[tag]: $tag" >> $USER.log
echo "======[versionQualifier]: $versionQualifier" >> $USER.log

# tag for eclipseInternalBuildTools on ottcvs1
internalToolsTag=$buildProjectTags
echo "======[internalToolsTag]: $internalToolsTag" >> $USER.log

# tag for exporting org.eclipse.releng.basebuilder
baseBuilderTag=$buildProjectTags
echo "======[baseBuilderTag]: $baseBuilderTag" >> $USER.log

# tag for exporting the custom builder
customBuilderTag=$buildProjectTags
echo "======[customBuilderTag]: $customBuilderTag" >> $USER.log

#if [ -e $builderDir ]
#then
#	 builderDir=$builderDir$timestamp
#fi

# directory where features and plugins will be compiled
buildDirectory=$HOME/releng.dtp.1100/src

echo "======[buildDirectory]: $buildDirectory" >> $USER.log

mkdir -p $builderDir
cd $builderDir


mkdir -p $postingDirectory/$buildLabel
#chmod -R 755 $builderDir

#default value of the bootclasspath attribute used in ant javac calls.  
#bootclasspath="/usr/local/j2sdk1.4.2_13/jre/lib/rt.jar:/usr/local/j2sdk1.4.2_13/jre/lib/jsse.jar:/usr/local/j2sdk1.4.2_13/jre/lib/jce.jar"
#bootclasspath="/usr/local/j2sdk1.4.2_13/jre/lib/rt.jar:/usr/local/j2sdk1.4.2_13/jre/lib/jsse.jar"

cd $HOME/releng.dtp.1100/org.eclipse.datatools.releng.builder

echo buildId=$buildId >> monitor.properties 
echo timestamp=$timestamp >> monitor.properties 
echo buildLabel=$buildLabel >> monitor.properties 
echo currentDay=$builddate >> monitor.properties
echo recipients=$recipients >> monitor.properties
echo sender=$sender >> monitor.properties
echo log=$postingDirectory/$buildLabel/index.php >> monitor.properties

#the base command used to run AntRunner headless
#antRunner="/usr/local/jdk1.5.0_09/bin/java -Xmx500m -jar ../org.eclipse.releng.basebuilder/plugins/org.eclipse.equinox.launcher.jar -Dosgi.os=linux -Dosgi.ws=gtk -Dosgi.arch=ppc -application org.eclipse.ant.core.antRunner"
#antRunner="/usr/local/j2sdk1.4.2_13/bin/java -Xmx500m -jar ../org.eclipse.releng.basebuilder/plugins/org.eclipse.equinox.launcher.jar -Dosgi.os=linux -Dosgi.ws=gtk -Dosgi.arch=ppc -application org.eclipse.ant.core.antRunner"
antRunner="$jvm16_home/bin/java -Xmx500m -jar ../org.eclipse.releng.basebuilder/plugins/org.eclipse.equinox.launcher.jar -Dosgi.os=linux -Dosgi.ws=gtk -Dosgi.arch=ppc -application org.eclipse.ant.core.antRunner"

echo "==========[antRunner]: $antRunner" >> $USER.log

#$HOME/releng.dtp.1100/BIRTBuilder/replaceBuildInfo.sh $buildinfoDate $buildinfounivDate

#clean drop directories

#full command with args
#buildId=v20110808-1451
echo $tagMaps >> $USER.log
echo $compareMaps >> $USER.log

PackageVersion=1.10.0M7-$timestamp
echo "======[PackageVersion]: $PackageVersion" >> $USER.log

#cp $HOME/releng.dtp.1100/dtpURLmonitor.properties $HOME/releng.260/src/

buildCommand="$antRunner -q -buildfile buildAll.xml $mail $testBuild $compareMaps \
-DmapVersionTag=$mapVersionTag -DpostingDirectory=$postingDirectory \
-Dbootclasspath=$bootclasspath_15 -DbuildType=$buildType -D$buildType=true \
-DbuildId=$buildId -Dbuildid=$buildId -DbuildLabel=$buildId -Dtimestamp=$timestamp $skipPerf $skipTest $tagMaps $noSign \
-DJ2SE-1.5=$bootclasspath_15 -DJavaSE-1.6=$bootclasspath_16 -DlogExtension=.xml $javadoc $updateSite $sign \
-Djava15-home=$bootclasspath_15 -DbuildDirectory=$HOME/releng.dtp.1100/src \
-DbaseLocation=$HOME/releng.dtp.1100/baseLocation -Dwtp.home=$HOME/releng.dtp.1100/baseLocation \
-DgroupConfiguration=true -DjavacVerbose=true -DjavacFailOnError=false \
-Dbasebuilder=$HOME/releng.dtp.1100/org.eclipse.releng.basebuilder  \
-Djvm15_home=$jvm15_home  -DmapTag.properties=$HOME/releng.dtp.1100/org.eclipse.datatools.releng.builder/mapTag.properties \
-Dbuild.date=$builddate -Dpackage.version=$PackageVersion \
-DmapGitRoot=$GitRepo \
-DmapVersionTag=$BranchName -DBranchVersion=1.10.0 \
-Dusername.sign=x -Dpassword.sign=x -Dhostname.sign=build.eclipse.org -Dhome.dir=x -Dsign.dir=/home/data/httpd/download-staging.priv/birt"

#-DjavacTarget=1.5 -DjavacSource=1.5 \

#-DmapCvsRoot=:ext:xgu@dev.eclipse.org:/cvsroot/datatools \
#-Ddtp.url.token=:ext:xgu@dev.eclipse.org:/cvsroot/datatools \
#-Ddtp.url.newvalue=:ext:xgu@192.168.218.218:/cvsroot/datatools"

#skipPreBuild

#capture command used to run the build
echo $buildCommand>command.txt

#run the build
$buildCommand >> $USER.log
#retCode=$?
#
#if [ $retCode != 0 ]
#then
#        echo "Build failed (error code $retCode)."
#        exit -1
#fi

#clean up
#rm -rf $builderDir
rm -rf $HOME/releng.dtp.1100/src/$buildId
#cp -f $HOME/releng.dtp.1100/src/directory.txt last_directory.txt

