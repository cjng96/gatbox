# https://
config = """
type: app
name: gatbox

serve:
  patterns: []

test:
  patterns: [ "*.dart" ]
  cmd: [ cmd.exe, /c, flutter, test ]

deploy:
  strategy: zip
  maxRelease: 3
  include:
    - src: build/web
      dest: .

servers:
  - name: dev
    host: watchmon.retailtrend.net
    port: 443
    id: ubuntu
    dkName: web
    dkId: root
    deployRoot: /data/gboxt

  - name: prod
    host: watchmon.retailtrend.net
    port: 443
    id: ubuntu
    dkName: web
    dkId: root
    deployRoot: /data/gbox

"""
import os, sys
import platform
import time

provisionPath = os.path.expanduser("~/iner/provision/")
sys.path.append(provisionPath)
import gat.plugin as my


# app.synapbook.com 도메인 등록을 nser/webser에서 한다. 그걸 디플로이 해놔야한다


class myGat:
    def __init__(self, helper, **_):
        helper.configStr("yaml", config)  # helper.configFile("yaml", "god.yaml")
        self.data = helper.loadData(os.path.join(provisionPath, ".data.yml"))

    def buildTask(self, util, local, **_):
        # local.gqlGen()
        # local.goBuild()
        # local.run("cmd flutter run -d chrome")
        # --web-renderer canvaskit html auto
        # 모바일에서 canvaskit하면 한글이 로드가 안된다
        # local.run("cmd flutter build web --no-sound-null-safety  --web-renderer html")
        flutter = "fvm flutter"
        if platform.system() == "Windows":
            flutter = "cmd flutter"
        # local.run(f"{flutter} build web --no-sound-null-safety")
        local.run(f"{flutter} build web --no-tree-shake-icons --web-renderer html")
        # html로 하니까 글자가 조금 진해진다

    # it's default operation and you can override running cmd
    # def runTask(self, util, local, **_):
    # 	return [util.config.config.name]

    def deployPreTask(self, util, remote, local, **_):
        remote.run(
            f"sudo mkdir -p {remote.server.deployRoot}"
        )  # && sudo chown cjng96: {remote.server.deployRoot}")

        pp = "./build/web/index.html"
        with open(pp, "r") as fp:
            ss = fp.read()

        ss = ss.replace('"main.dart.js"', '"main.dart.js?v=%d"' % int(time.time()))
        print(ss)
        with open("./build/web/index.html", "w") as fp:
            fp.write(ss)

    def deployPostTask(self, util, remote, local, **_):
        # remote.pm2Register():
        # local.run("cd %%s/current && echo 'finish'" %% util.deployRoot)

        # from now on, html nginx service setting is done on webser app
        # my.nginxWebSite(remote, name=remote.vars.webName, domain=remote.vars.domain, root='%s/current' % remote.server.deployRoot, cacheOn=True)

        pass
