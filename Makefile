CONTEXT = acme
VERSION = v3.7
IMAGE_NAME = starter-api
REGISTRY = docker-registry.default.svc.cluster.local:5000
OC_USER=developer
OC_PASS=developer

# Allow user to pass in OS build options
docker login -u='6280466|shanpagoti' -p=eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiI0MjY5NzcxNTcwYjE0ZjdjYjczYjZmMDNmZTNjOGI4ZSJ9.Vyz2XxcZE6K7C3MxD--Ty_5t21SSbcCrh1tNmUkXJ50MehBuHrgCYxff-bx6TonB2bzmX31CvFea5z_SYUFcfcYd6m4U8JsRS2msIaUuC_DKlU8rq2PXbkxTXPU9_MeAEl3oC-rAwDuc5JtrAm3F1jWkojVrGIzS2NKml8uAPj8hdm6xKiiHSuycxi47Dqm25gv3tBYK2FSXUZdgovuK7vaPcGc9cHEdURVVI7Bg8yuyRZh5mAMrQpYfZe_b-ka8bB9FoiFfsRQPZTVMvwd0M6p9jTB7P67jkEBEkcIXRpEPPVZKv8DNAu7CyRrO46trgP7b15jNsHIoqrJqerCrv2lv1KU1-fpcrl6TqFA6hpEvWTDub93QS-rHF1lQMevGV_rYg1VbtRWU5CpsSCr9VuDSa785AoRkLMkN9gEfVGz0VcWOcrU1PJ3nrtJOtbzMDtC_mHdqTDGKeYvP65yrQ2uxaTQWXwMpQUME1Uyl2eg0uNdgfWpVdbvHOOnGcELhGUfpyur5H9NcXL0hSWsqu3C4-OSAZTVw60tRjf9rBrVw3DShNxxzRLD4ettylHu0eY149DR7QQa__PYQi0u6POK1ZddLnD9Ozlnn6Np2lEP6EEBfY-yafrfG8Nq1zkLxtLBWtT5lDBYCEX08y16ejs6UemBqU8V3zy5MTfH_aUg registry.redhat.io
ifeq ($(TARGET),centos7)
	DFILE := Dockerfile.${TARGET}
else
	TARGET := rhel7
	DFILE := Dockerfile
endif

all: build
build:
	docker build --pull -t ${CONTEXT}/${IMAGE_NAME}:${TARGET}-${VERSION} -t ${CONTEXT}/${IMAGE_NAME} -f ${DFILE} .
	@if docker images ${CONTEXT}/${IMAGE_NAME}:${TARGET}-${VERSION}; then touch build; fi

lint:
	dockerfile_lint -f Dockerfile
	dockerfile_lint -f Dockerfile.centos7

test:
	$(eval CONTAINERID=$(shell docker run -tdi -u $(shell shuf -i 1000010000-1000020000 -n 1) \
	--cap-drop=KILL \
	--cap-drop=MKNOD \
	--cap-drop=SYS_CHROOT \
	--cap-drop=SETUID \
	--cap-drop=SETGID \
	${CONTEXT}/${IMAGE_NAME}:${TARGET}-${VERSION}))
	@sleep 3
	@docker exec ${CONTAINERID} ps aux
	@docker rm -f ${CONTAINERID}

openshift-test:
	$(eval PROJ_RANDOM=test-$(shell shuf -i 100000-999999 -n 1))
	oc login --token=${OC_PASS}
	oc new-project ${PROJ_RANDOM}
	docker login -u ${OC_USER} -p ${OC_PASS} ${REGISTRY}
	docker tag ${CONTEXT}/${IMAGE_NAME}:${TARGET}-${VERSION} ${REGISTRY}/${PROJ_RANDOM}/${IMAGE_NAME}
	docker push ${REGISTRY}/${PROJ_RANDOM}/${IMAGE_NAME}
	oc new-app -i ${IMAGE_NAME}
	oc rollout status -w dc/${IMAGE_NAME}
	oc status
	sleep 5
	oc describe pod `oc get pod --template '{{(index .items 0).metadata.name }}'`
	oc exec `oc get pod --template '{{(index .items 0).metadata.name }}'` ps aux

run:
	docker run -tdi -u $(shell shuf -i 1000010000-1000020000 -n 1) \
	--cap-drop=KILL \
	--cap-drop=MKNOD \
	--cap-drop=SYS_CHROOT \
	--cap-drop=SETUID \
	--cap-drop=SETGID \
	${CONTEXT}/${IMAGE_NAME}:${TARGET}-${VERSION}

clean:
	rm -f build