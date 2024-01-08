"""
lib/coDart는 win에서 //wsl$/로 걸어놓은 링크라서 반대로 wsl내에서는 접근이 안된다.
그래서 로칼에서는 제외하고 별도로 deploy.include를 걸어놨다
"""

config = """
name: gatbox
type: app

serve:
  patterns: [ "*.go", "*.yml", "*.graphql" ]

deploy:
  strategy: zip
  followLinks: True
  maxRelease: 3
  include:
    - "*"
    - src: ../../coDart
      dest: coDart
      exclude:
        - .git/* 

  exclude:
    - .dart_tool
    - __pycache__
    - config/*my.yml
    - repos


  sharedLinks: []
    #- .dart_tool/

defaultVars:
  dbDocker: sql
  webDocker: web
  profile: dev

servers:
  - name: dev
    host: watchmon.retailtrend.net
    port: 443
    id: ubuntu
    deployRoot: /app
    vars:
      profile: dev
      httpApi: gatboxt.retailtrend.net
      dkName: gboxt
      root: /data/gboxt/current

  - name: prod
    host: watchmon.retailtrend.net
    port: 443
    id: ubuntu
    deployRoot: /app
    vars:
      profile: prod
      httpApi: gatbox.retailtrend.net
      dkName: gbox
      root: /data/gbox/current

"""

import os
import sys

import yaml

# import string
# import random
# import subprocess

provisionPath = os.path.expanduser("~/iner/provision/")
sys.path.insert(0, provisionPath)
import gat.plugin as my


def loadFile(pp):
    with open(pp, "r") as fp:
        return fp.read()


class myGat:
    def __init__(self, helper, **_):
        helper.configStr("yaml", config)
        self.data = helper.loadData(os.path.join(provisionPath, ".data.yml"))

    # return: False(stop post processes)
    def buildTask(self, util, local, **kwargs):
        # local.gqlGen()
        # local.goBuild()
        pass

    def setupTask(self, util, local, remote, **_):
        baseName, baseVer = my.dockerCoImage(remote, dartVer="3.2.3")

        appBaseName = "gboximg"
        appBaseVer, hash = my.baseCheckVersion(
            remote, ["pubspec.yaml"], appBaseName, f"{baseVer}."
        )

        def update1(env):
            env.run("cd /etc/service && rm -rf sshd cron")

            env.run("mkdir -p /app/cache")

            ss = loadFile("pubspec.yaml")
            dd = yaml.load(ss, Loader=yaml.FullLoader)
            del dd["dependencies"]["codart"]
            ss = yaml.dump(dd)
            env.makeFile(ss, "/app/cache/pubspec.yaml")
            # env.copyFile("pubspec.yaml", "/app/cache/pubspec.yaml")

            # 이거 해놓으면 본체 할때 17 -> 10초로
            env.run(f"cd /app/cache && dart pub get")  # 최소 3기가가 필요하다.

        my.dockerUpdateImage(
            remote,
            baseName=baseName,
            baseVer=baseVer,
            newName=appBaseName,
            newVer=appBaseVer,
            hash=hash,
            func=update1,
        )

        dkImg = "gbox"  # 이건 나중에 바꾸자
        # dkVer = my.deployCheckVersion(util)
        # dkVer = f"{baseVer}.{dkVer}"
        dkVer, hash = my.deployCheckVersion(remote, util, dkImg, f"{appBaseVer}.")
        # print(f"dk ver {dkVer}")

        def update2(env):
            env.deployApp(
                "./gat_app",
                profile=remote.server.name,
                serverOvr=dict(dkName=dkImg + "-con"),
                varsOvr=dict(startDaemon=False, sepDk=True),
            )

        # 이미지는 모두 동일하고, 환경은 실행할때 변수로 주자
        my.dockerUpdateImage(
            remote,
            baseName=appBaseName,
            baseVer=appBaseVer,
            newName=dkImg,
            newVer=dkVer,
            hash=hash,
            func=update2,
        )

        if remote.runFlag:
            # remote.run(f'echo {remote.vars.profile} > {remote.server.deployPath}/profile.env')
            my.dockerRunCmd(
                remote.vars.dkName,
                f"{dkImg}:{dkVer}",
                env=remote,
                net="net",
                extra=f"-e PROFILE={remote.server.name}",
            )
            dk = remote.dockerConn(remote.vars.dkName)
            my.promptSet(dk, f"{dkImg}_{remote.server.name}")

            # dbPw = self.data.apps[remote.vars.dkName].dbPw
            #             dk.makeFile(
            #                 content=f"""
            # gmail:
            #   id: {remote.data.gmail.id}
            #   pw: {remote.data.gmail.pw}
            #   to: {remote.data.gmail.to}
            # """,
            #                 path="/app/current/config/my.yml",
            #             )

            my.writeRunScript(
                dk,
                f"""\
cd /app/current
if [ "$ENV" = "test" ]; then
  exec ./gbox
else
  # exec ./es > /dev/null 2>&1
  exec ./gbox
fi
""",
            )
            # 로그는 main.dart에서 자체적으로 /work/app.log로 저장하므로
            # dk.run(f"sudo mkdir -p /work/attach")

            # init nginx
            with open(f"config/{remote.vars.profile}.yml", "r") as fp:
                config = yaml.safe_load(fp.read())

            proxyUrl = f"http://{remote.vars.dkName}:{config['port']}"

            web = remote.dockerConn(remote.vars.webDocker)  # , dkId=remote.server.id)
            rel = remote.server.name != "dev"
            usingProxy = not rel
            usingProxy = False  # m1일때만
            privateFilter = (
                """\
# allow 172.0.0.0/8; # docker - webser는 직접 포트로 접근하던지 해야한다.
allow 14.36.117.177; # rt
allow 182.211.75.144; # gongdug
"""
                if rel
                else "allow all;"
            )

            my.setupWebApp(
                web,
                name=remote.vars.dkName,
                domain=remote.vars.httpApi,
                certAdminEmail="cjng96@gmail.com",
                root=remote.vars.root,
                proxyUrl=proxyUrl,
                publicApi="/api",
                # privateApi="/pcmd",
                # privateFilter=privateFilter,
                wsPath="/ws",
                maxBodySize="10m",
                # certSetup=not usingProxy,
                certSetup=False,  # watchmon에서는 못한다
                buffering=False,
            )

            if usingProxy:
                # m1일때만 - setup n2 proxy
                proxy = remote.remoteConn(
                    "nas.mmx.kr", port=13522, id="cjng96", dkName="web"
                )
                my.setupWebApp(
                    proxy,
                    name=remote.vars.dkName,
                    domain=remote.vars.httpApi,
                    certAdminEmail="cjng96@gmail.com",
                    proxyUrl="http://192.168.1.136",
                    publicApi="/",
                    privateApi="/pcmd",
                    privateFilter=privateFilter,
                    wsPath="/ws",
                    maxBodySize="10m",
                    buffering=False,
                )

    def deployPreTask(self, util, remote, local, **_):
        # create new user with ssh key
        # remote.userNew(remote.server.owner, existOk=True, sshKey=True)
        # remote.run('sudo adduser {{remote.server.id}} {{remote.server.owner}}')
        # remote.run('sudo touch {0} && sudo chmod 700 {0}'.format('/home/{{server.owner}}/.ssh/authorized_keys'))
        # remote.strEnsure("/home/{{server.owner}}/.ssh/authorized_keys", local.strLoad("~/.ssh/id_rsa.pub"), sudo=True)

        # subprocess.check_call("dart test", shell=True)

        if not remote.vars.get("sepDk"):
            raise Exception(
                "direct deployment is not supported. you should use setup feature."
            )

        return

        if remote.vars.sepDk:
            pass
        else:
            # 현재 user만들고 sv조작때문에 sudo가 필요하다
            pubs = list(map(lambda x: x["key"], self.data.sshPub))
            pubs.append(local.strLoad("~/.ssh/id_rsa.pub"))
            my.makeUser(remote, id=remote.server.owner, authPubs=pubs)
            remote.run(f"sudo adduser {remote.server.id} {remote.server.owner}")

        # download ssh key files and register those
        # ssh_pub_user = ""
        # local.run("mkdir -p ./work/pub/%s" % ssh_pub_user)
        # local.s3List("comp-priv", "pub/%s" % ssh_pub_user)

        # common, coDart 둘다 win link인데 common은 c:\경로라 wsl에서 동작하는데
        # coDart는 \\wsl$\ 경로라서 wsl에서 인식을 못한다.
        # subprocess.check_call('rm lib/coDart')
        # subprocess.check_call('ln -sf ~/iner/coDart lib/coDart')

    def deployPostTask(self, util, remote, local, **_):
        # remote.run('mkdir -p {{deployRoot}}/shared/log')

        # install dart
        # my.installDart(remote)

        # 참고 경로로
        remote.run("ln -sf /app/current/coDart /app/coDart")
        # remote.run("ln -sf /app/current/mysql1_dart /app/mysql1_dart")

        # /app/cache에서 한번 해놔서 여기선 속도가 빠르다
        ss = loadFile("pubspec.yaml")
        dd = yaml.load(ss, Loader=yaml.FullLoader)
        dd["dependencies"]["codart"]["path"] = "coDart"
        ss = yaml.dump(dd)
        remote.makeFile(ss, "/app/current/pubspec.yaml")

        remote.run(f"cd {remote.server.deployPath} && dart pub get")  # 최소 3기가가 필요하다.
        # remote.run(f"sudo chown {remote.server.owner}: {remote.server.deployPath}/.dart_tool -R")
        # remote.run(f"sudo chmod 775 {remote.server.deployPath}/.dart_tool -R")  # cjng96가 이후 수정 삭제할수 있도록

        # build json structure file - 복사니까 일단은 상관없다.

        # 빌드해서 실행하면 230MB -> 16MB로 메모리 소모량이 줄어든다. dart_tool은 필요하다. 빌드시간 15초
        # remote.run(f"cd {remote.server.deployPath} && /usr/lib/dart/bin/dart2native lib/main.dart -o neng")
        remote.run(
            f"cd {remote.server.deployPath} && /usr/lib/dart/bin/dart compile exe lib/main.dart -o gbox"
        )
