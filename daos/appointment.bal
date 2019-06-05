import ballerina/io;

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
