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

    labels = modified_info_object["metadata"]["labels"]

    for container_spec in modified_info_object["spec"]["template"]["spec"]["containers"]:
        print("Let's check pod name of {}/{}... \n".format(modified_info_object["metadata"]["name"], container_spec['name']))
        modify_request_cpu(container_spec, labels)

    patch = jsonpatch.JsonPatch.from_diff(request_info_object, modified_info_object)
    print("############################## JSON Patch ############################### ")
    pprint(str(patch))
    print('\n')

    admissionReview = patch_admission(request_info, patch)
    print("######################## AdmissionReview to Kubernetes  ########################")
    pprint(admissionReview)
    print('\n')

    return jsonify(admissionReview)

def modify_request_cpu(container_spec, labels):
    if labels["sparkoperator.k8s.io/launched-by-spark-operator"] = "true":
        request_cpu = container_spec["resources"]["requests"]["cpu"] = "100m"
    else:
        pass
      
def patch_admission(request_info, patch):
    admissionReview = {
        "response": {
            "allowed": True,
            "uid": request_info["request"]["uid"],
            "patch": base64.b64encode(str(patch).encode()).decode(),
            "patchtype": "JSONPatch"
        }
    }
    return admissionReview
  
if __name__=='__main__':
    app.run(host='0.0.0.0', debug=False, ssl_context=('/run/secrets/tls/tls.crt', '/run/secrets/tls/tls.key'))
