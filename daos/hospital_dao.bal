import ballerina/http;
import ballerina/log;

public type HospitalDAO record {
    Doctor[] doctorsList = [];
    string[] categories = [];
    map<Patient> patientMap = {

    };
    map<PatientRecord> patientRecordMap = {

    };
};

type NotFoundError error<string>;

public function findDoctorByCategory(HospitalDAO hospitalDao, string category) returns Doctor?[] {
    Doctor?[] list = [];
    foreach var d in hospitalDao.doctorsList {
        // if (d is Doctor) {
            if (category.equalsIgnoreCase(d.category)) {
                list[list.length()] = d;
            }
        // }
    }
    return list;
}

public function findDoctorByName(HospitalDAO hospitalDao, string name) returns Doctor|NotFoundError {
    foreach var d in hospitalDao.doctorsList {
        // if (d is Doctor) {
            if (name.equalsIgnoreCase(d.name)) {
                return d;
            }
        // }
    }
    string errorReason = "Doctor Not Found: " + name;
    NotFoundError notFoundError = error(errorReason);
    return notFoundError;
}
