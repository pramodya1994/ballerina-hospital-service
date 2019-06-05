public type HealthcareDao record {
    Doctor[] doctorsList = [];
    string[] catergories = [];
    map<Payment> payments = {};
};

public type Payment record {
    int appointmentNo;
    string doctorName;
    string patient;
    float actualFee;
    int discount;
    float discounted;
    string paymentID;
    string status;
};

public type PaymentSettlement record {
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    float fee;
    boolean confirmed;
    string cardNumber;
};

public type ChannelingFee record {
    string patientName;
    string doctorName;
    string actualFee;
};

type DoctorNotFoundError error<string>;

public function findDoctorByCategoryFromHealthcareDao(HealthcareDao healthcareDao, string category) returns Doctor[] {
    Doctor[] list = [];
    foreach var d in healthcareDao.doctorsList {
        if (category.equalsIgnoreCase(d.category)){
            list[list.length()] = d;     
        }
    }
    return list;
}

public function findDoctorByNameFromHelathcareDao(HealthcareDao healthcareDao, string name) returns Doctor|DoctorNotFoundError {
    foreach var d in healthcareDao.doctorsList {
        if (name.equalsIgnoreCase(d.name)) {
            return d;
        }
    }
    string errorReason = "Doctor Not Found: " + name;
    DoctorNotFoundError docNotFoundError = error(errorReason);
    return docNotFoundError;
}