@Library('StanUtils')
import org.stan.Utils

def utils = new org.stan.Utils()

def skipRemainingStages = false
def buildingAgentARM = "linux"

/* Functions that runs a sh command and returns the stdout */
def runShell(String command){
    def output = sh (returnStdout: true, script: "${command}").trim()
    return "${output}"
}

def tagName() {
    if (env.TAG_NAME) {
        env.TAG_NAME
    } else if (env.BRANCH_NAME == 'master') {
        'nightly'
    } else {
        'unknown-tag'
    }
}

pipeline {
    agent none
    options {parallelsAlwaysFailFast()}
    stages {
        stage('Kill previous builds') {
            when {
                not { branch 'develop' }
                not { branch 'master' }
                not { branch 'downstream_tests' }
            }
            steps { script { utils.killOldBuilds() } }
        }
        stage('Verify changes') {
            agent { label 'linux' }
            steps {
                script {
                    retry(3) { checkout scm }
                    sh 'git clean -xffd'


                    def sourceCodePaths = ['src'].join(" ")
                    skipRemainingStages = utils.verifyChanges(sourceCodePaths)

                    if (buildingTag()) {
                        buildingAgentARM = "arm-ec2"
                    }
                }
            }
        }
        stage("Build") {
            when {
                beforeAgent true
                expression {
                    !skipRemainingStages
                }
            }
            agent {
                docker {
                    image 'stanorg/stanc3:debian'
                    //Forces image to ignore entrypoint
                    args "-u root --entrypoint=\'\'"
                }
            }
            steps {
                runShell("""
                    eval \$(opam env)
                    dune build @install
                """)
            }
            post { always { runShell("rm -rf ./*") }}
        }
        stage("Code formatting") {
            when {
                beforeAgent true
                expression {
                    !skipRemainingStages
                }
            }
            agent {
                docker {
                    image 'stanorg/stanc3:debian'
                    //Forces image to ignore entrypoint
                    args "-u root --entrypoint=\'\'"
                }
            }
            steps {
                sh """
                    eval \$(opam env)
                    make format  ||
                    (
                        set +x &&
                        echo "The source code was not formatted. Please run 'make format; dune promote' and push the changes." &&
                        echo "Please consider installing the pre-commit git hook for formatting with the above command." &&
                        echo "Our hook can be installed with bash ./scripts/hooks/install_hooks.sh" &&
                        exit 1;
                    )
                """
            }
            post { always { runShell("rm -rf ./*") }}
        }
        stage("OCaml tests") {
            when {
                beforeAgent true
                expression {
                    !skipRemainingStages
                }
            }
            parallel {
                stage("Dune tests") {
                    agent {
                        docker {
                            image 'stanorg/stanc3:debian'
                            //Forces image to ignore entrypoint
                            args "-u root --entrypoint=\'\'"
                        }
                    }
                    steps {
                        runShell("""
                            eval \$(opam env)
                            dune runtest
                        """)
                    }
                    post { always { runShell("rm -rf ./*") }}
                }
                stage("TFP tests") {
                    agent {
                        docker {
                            image 'tensorflow/tensorflow@sha256:08901711826b185136886c7b8271b9fdbe86b8ccb598669781a1f5cb340184eb'
                            args '-u root'
                        }
                    }
                    steps {
                        sh "pip3 install tfp-nightly==0.11.0.dev20200516"
                        sh "python3 test/integration/tfp/tests.py"
                    }
                    post { always { runShell("rm -rf ./*") }}
                }
            }
        }
        stage("Build and test static release binaries") {
            failFast true
            parallel {
                stage("Build & test Mac OS X binary") {
                    when {
                        beforeAgent true
                        expression {
                            !skipRemainingStages
                        }
                    }
                    agent { label "osx && ocaml" }
                    steps {
                        runShell("""
                            opam switch 4.12.0
                            eval \$(opam env)
                            opam update || true
                            bash -x scripts/install_build_deps.sh
                            dune subst
                            dune build @install
                        """)

                        sh "mkdir -p bin && mv _build/default/src/stan2tfp/stan2tfp.exe bin/mac-stan2tfp"

                        stash name:'mac-exe', includes:'bin/*'
                    }
                    post { always { runShell("rm -rf ./*") }}
                }

                stage("Build & test a static Linux binary") {
                    when {
                        beforeAgent true
                        expression {
                            !skipRemainingStages
                        }
                    }
                    agent {
                        docker {
                            image 'stanorg/stanc3:static'
                            //Forces image to ignore entrypoint
                            args "-u 1000 --entrypoint=\'\'"
                        }
                    }
                    steps {
                        runShell("""
                            eval \$(opam env)
                            dune subst
                            dune build @install --profile static
                        """)

                        sh "mkdir -p bin && mv `find _build -name stan2tfp.exe` bin/linux-stan2tfp"

                        stash name:'linux-exe', includes:'bin/*'
                    }
                    post {always { runShell("rm -rf ./*")}}
                }

                stage("Build & test a static Linux mips64el binary") {
                    when {
                        beforeAgent true
                        allOf {
                            expression { !skipRemainingStages }
                            anyOf { buildingTag(); branch 'master' }
                        }
                    }
                    agent {
                        docker {
                            image 'stanorg/stanc3:static'
                            //Forces image to ignore entrypoint
                            args "-u 1000 --entrypoint=\'\' -v /var/run/docker.sock:/var/run/docker.sock"
                        }
                    }
                    steps {
                        runShell("""
                            eval \$(opam env)
                            dune subst
                        """)
                        sh "sudo apk add docker jq"
                        sh "sudo bash -x src/stanc3/scripts/build_multiarch_stanc3.sh mips64el"

                        sh "mkdir -p bin && mv `find _build -name stan2tfp.exe` bin/linux-mips64el-stan2tfp"

                        stash name:'linux-mips64el-exe', includes:'bin/*'
                    }
                    post {always { runShell("rm -rf ./*")}}
                }

                stage("Build & test a static Linux ppc64el binary") {
                    when {
                        beforeAgent true
                        allOf {
                            expression { !skipRemainingStages }
                            anyOf { buildingTag(); branch 'master' }
                        }
                    }
                    agent {
                        docker {
                            image 'stanorg/stanc3:static'
                            //Forces image to ignore entrypoint
                            args "-u 1000 --entrypoint=\'\' -v /var/run/docker.sock:/var/run/docker.sock"
                        }
                    }
                    steps {
                        runShell("""
                            eval \$(opam env)
                            dune subst
                        """)
                        sh "sudo apk add docker jq"
                        sh "sudo bash -x src/stanc3/scripts/build_multiarch_stanc3.sh ppc64el"

                        sh "mkdir -p bin && mv `find _build -name stan2tfp.exe` bin/linux-ppc64el-stan2tfp"

                        stash name:'linux-ppc64el-exe', includes:'bin/*'
                    }
                    post {always { runShell("rm -rf ./*")}}
                }

                stage("Build & test a static Linux s390x binary") {
                    when {
                        beforeAgent true
                        allOf {
                            expression { !skipRemainingStages }
                            anyOf { buildingTag(); branch 'master' }
                        }
                    }
                    agent {
                        docker {
                            image 'stanorg/stanc3:static'
                            //Forces image to ignore entrypoint
                            args "-u 1000 --entrypoint=\'\' -v /var/run/docker.sock:/var/run/docker.sock"
                        }
                    }
                    steps {
                        runShell("""
                            eval \$(opam env)
                            dune subst
                        """)
                        sh "sudo apk add docker jq"
                        sh "sudo bash -x src/stanc3/scripts/build_multiarch_stanc3.sh s390x"

                        sh "mkdir -p bin && mv `find _build -name stan2tfp.exe` bin/linux-s390x-stan2tfp"

                        stash name:'linux-s390x-exe', includes:'bin/*'
                    }
                    post {always { runShell("rm -rf ./*")}}
                }

                stage("Build & test a static Linux arm64 binary") {
                    when {
                        beforeAgent true
                        allOf {
                            expression { !skipRemainingStages }
                            anyOf { buildingTag(); branch 'master' }
                        }
                    }
                    agent {
                        docker {
                            image 'stanorg/stanc3:static'
                            //Forces image to ignore entrypoint
                            label 'linux-ec2'
                            args "-u 1000 --entrypoint=\'\' -v /var/run/docker.sock:/var/run/docker.sock"
                        }
                    }
                    steps {
                        runShell("""
                            eval \$(opam env)
                            dune subst
                        """)
                        sh "sudo apk add docker jq"
                        sh "sudo bash -x src/stanc3/scripts/build_multiarch_stanc3.sh arm64"

                        sh "mkdir -p bin && mv `find _build -name stan2tfp.exe` bin/linux-arm64-stan2tfp"

                        stash name:'linux-arm64-exe', includes:'bin/*'
                    }
                    post {always { runShell("rm -rf ./*")}}
                }

                stage("Build & test a static Linux armhf binary") {
                    when {
                        beforeAgent true
                        allOf {
                            expression { !skipRemainingStages }
                            anyOf { buildingTag(); branch 'master' }
                        }
                    }
                    agent {
                        docker {
                            image 'stanorg/stanc3:static'
                            //Forces image to ignore entrypoint
                            label 'linux-ec2'
                            args "-u 1000 --entrypoint=\'\' -v /var/run/docker.sock:/var/run/docker.sock"
                        }
                    }
                    steps {
                        runShell("""
                            eval \$(opam env)
                            dune subst
                        """)
                        sh "sudo apk add docker jq"
                        sh "sudo bash -x src/stanc3/scripts/build_multiarch_stanc3.sh armhf"

                        sh "mkdir -p bin && mv `find _build -name stan2tfp.exe` bin/linux-armhf-stan2tfp"

                        stash name:'linux-armhf-exe', includes:'bin/*'
                    }
                    post {always { runShell("rm -rf ./*")}}
                }

                stage("Build & test a static Linux armel binary") {
                    when {
                        beforeAgent true
                        allOf {
                            expression { !skipRemainingStages }
                            anyOf { buildingTag(); branch 'master' }
                        }
                    }
                    agent {
                        docker {
                            image 'stanorg/stanc3:static'
                            //Forces image to ignore entrypoint
                            label 'linux-ec2'
                            args "-u 1000 --entrypoint=\'\' -v /var/run/docker.sock:/var/run/docker.sock"
                        }
                    }
                    steps {
                        runShell("""
                            eval \$(opam env)
                            dune subst
                        """)
                        sh "sudo apk add docker jq"
                        sh "sudo bash -x src/stanc3/scripts/build_multiarch_stanc3.sh armel"

                        sh "mkdir -p bin && mv `find _build -name stan2tfp.exe` bin/linux-armel-stan2tfp"

                        stash name:'linux-armel-exe', includes:'bin/*'
                    }
                    post {always { runShell("rm -rf ./*")}}
                }

                // Cross compiling for windows on debian
                stage("Build & test static Windows binary") {
                    when {
                        beforeAgent true
                        expression {
                            !skipRemainingStages
                        }
                    }
                    agent {
                        docker {
                            image 'stanorg/stanc3:debian-windows'
                            label 'linux-ec2'
                            //Forces image to ignore entrypoint
                            args "-u 1000 --entrypoint=\'\'"
                        }
                    }
                    steps {

                        runShell("""
                            eval \$(opam env)
                            dune subst
                            dune build -x windows
                        """)

                        sh "mkdir -p bin && mv _build/default.windows/src/stan2tfp/stan2tfp.exe bin/windows-stan2tfp"

                        stash name:'windows-exe', includes:'bin/*'
                    }
                    post {always { runShell("rm -rf ./*")}}
                }
            }

        }
        stage("Release tag and publish binaries") {
            when {
                beforeAgent true
                allOf {
                    expression { !skipRemainingStages }
                    anyOf { buildingTag(); branch 'master' }
                }
            }
            agent { label 'linux' }
            environment { GITHUB_TOKEN = credentials('6e7c1e8f-ca2c-4b11-a70e-d934d3f6b681') }
            steps {
                unstash 'windows-exe'
                unstash 'linux-exe'
                unstash 'mac-exe'
                unstash 'linux-mips64el-exe'
                unstash 'linux-ppc64el-exe'
                unstash 'linux-s390x-exe'
                unstash 'linux-arm64-exe'
                unstash 'linux-armhf-exe'
                unstash 'linux-armel-exe'
                runShell("""
                    wget https://github.com/tcnksm/ghr/releases/download/v0.12.1/ghr_v0.12.1_linux_amd64.tar.gz
                    tar -zxvpf ghr_v0.12.1_linux_amd64.tar.gz
                    ./ghr_v0.12.1_linux_amd64/ghr -recreate ${tagName()} bin/
                """)
            }
        }
    }
    post {
       always {
          script {utils.mailBuildResults()}
        }
    }
}
