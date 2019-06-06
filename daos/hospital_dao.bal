import ballerina/http;
import ballerina/log;
import ballerina/time;

public type HospitalDAO record {
    Doctor[] doctorsList = [];
    string[] categories = [];
    map<Patient> patientMap = {};
    map<PatientRecord> patientRecordMap = {};
};

public type AppointmentRequest record {
    Patient patient;
    string doctor;
    string hospital;
    string appointmentDate;
};

public type Appointment record {
    string time?;
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital?;
    float fee;
    boolean confirmed;
    string paymentID?;
    string appointmentDate?;
};

public type Doctor record {
    string name;
    string hospital;
    string category;
    string availability;
    float fee;
};

public type Patient record {
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
};

public type PatientRecord record {
    Patient patient;
    map<string[]> symptoms = {};
    map<string[]> treatments = {};
};

public function updateTreatmentsInPatientRecord(PatientRecord patientRecord, string[] treatments) returns boolean {
    time:Time currentTime = time:currentTime();
    var date = time:format(currentTime, "dd-MM-yyyy");
    if date is error {
        log:printError("Error getting the current date.");
        return false;
    } else {
        patientRecord.treatments[date] = treatments;
        return true;
    }
}

public function updateSymptomsInPatientRecord(PatientRecord patientRecord, string[] symptoms) returns boolean {
    time:Time currentTime = time:currentTime();
    var date = time:format(currentTime, "dd-MM-yyyy");
    if date is error {
        log:printError("Error getting the current date.");
        return false;
    } else {
        patientRecord.symptoms[date] = symptoms;
        return true;
    }
}

public function findDoctorByCategory(HospitalDAO hospitalDao, string category) returns Doctor[] {
    Doctor[] list = [];
    foreach Doctor doctor in hospitalDao.doctorsList {
        if (category.equalsIgnoreCase(doctor.category)) {
            list[list.length()] = doctor;
        }
    }
    return list;
}

public function findDoctorByName(HospitalDAO hospitalDao, string name) returns Doctor | DoctorNotFoundError {
    foreach var doctor in hospitalDao.doctorsList {
        if (name.equalsIgnoreCase(doctor.name)) {
            return doctor;
        }
    }
    string errorReason = "Doctor Not Found: " + name;
    DoctorNotFoundError notFoundError = error(errorReason);
    return notFoundError;
}
