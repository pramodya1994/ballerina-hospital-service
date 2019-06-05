
type NotFoundError error<string>;

public function containsStringElement(string[] arr, string element) returns boolean {
    foreach var item in arr {
        if (item.equalsIgnoreCase(element)) {
            return true;
        }
    }
    return false;
}

public function containsInPatientRecordMap(map<daos:PatientRecord> patientRecordMap, string ssn) returns boolean {
    foreach (string, daos:PatientRecord) (k, v) in patientRecordMap {
        daos:Patient patient = <daos:Patient> v["patient"];
        if (<boolean>patient["ssn"].equalsIgnoreCase(ssn)) {
            return true;
        }
    }
    return false;
}

public function convertJsonToStringArray(json[] array) returns string[] {
    string[] result = [];
    foreach var item in array {
        result[result.length()] = <string>item;
    }
    return result;
}









