package system

main = {
  "apiVersion": "admission.k8s.io/v1beta1",
  "kind": "AdmissionReview",
  "response": response
}

default response = { "allowed": true }

response = {
    "allowed": false,
    "status": {
        "reason": reason
    }
} {
    reason = concat(", ", deny)
    reason != ""
}

deny[msg] {
  input.request.operation == "CREATE"
  input.request.kind.kind == "Pod"
  msg := sprintf("Pod is not allowed to be created by %s", [input.request.userInfo.username])
}