from flask import Flask, request, jsonify
from pprint import pprint
import jsonpatch
import copy
import base64

app = Flask(__name__)


@app.route('/mutate', methods=['POST'])
def webhook():
    request_info = request.json
    request_info_object = request_info["request"]["object"]

    modified_info = copy.deepcopy(request_info)
    pprint(modified_info)
    modified_info_object = modified_info["request"]["object"]

    stage = modified_info_object["metadata"]["annotation"]["stage"]

    for container_spec in modified_info_object["spec"]["template"]["spec"]["containers"]:
        print("Let's check image name of {}/{}... \n".format(modified_info_object["metadata"]["name"], container_spec['name']))
        check_image_name(container_spec, stage)

    if stage == 'dev':
        patch = jsonpatch.JsonPatch.from_diff(request_info_object, modified_info_object)
        print("############## JSON Patch ############## ")
        pprint(str(patch))
        print('\n')

        admissionReview = {
            "response": {
                "allowed": True,
                "uid": request_info["request"]["uid"],
                "patch": base64.b64encode(str(patch).encode()).decode(),
                "patchtype": "JSONPatch",
            }
        }

        print("############## This data will be sent to k8s (admissionReview) ##############")
        pprint(admissionReview)
        print('\n')

    if stage == 'prd':
        admissionReview = {
            "response": {
                "allowed": False,
                "uid": request_info["request"]["uid"],
                "status":{
                    "message": "Denied because of stage is prd"
                }
            }
        }

    return jsonify(admissionReview)


def check_image_name(container_spec, stage):
    image = container_spec["image"]

    if 'kakaobank.harbor' not in image:
        if '/' in image:
            split_image = image.split('/', 1)[1]
            modified_image = 'kakaobank.harbor.' + stage + '/' + split_image
        else:
            modified_image = 'kakaobank.harbor.' + stage + '/' + image
        container_spec["image"] = modified_image

if __name__=='__main__':
    app.run(host='0.0.0.0', debug=True, ssl_context=('/run/secrets/tls/tls.crt', '/run/secrets/tls/tls.key'))