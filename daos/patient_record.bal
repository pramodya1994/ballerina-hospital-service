import ballerina/io;
import ballerina/time;

public type PatientRecord record {
    Patient patient;
    map<string[]> symptoms = {

    };
    map<string[]> treatments = {

    };
};

public function updateTreatmentsInPatientRecord(PatientRecord patientRecord, string[] treatments) returns boolean {
    time:Time currentTime = time:currentTime();
    var date = time:format(currentTime, "dd-MM-yyyy");
    if date is error {
        log:printError("error getting the current date");
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
        log:printError("error getting the current date");
        return false;
    } else {
        patientRecord.symptoms[date] = symptoms;
        return true;
    }
}
