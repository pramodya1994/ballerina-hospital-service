import daos;
import ballerina/io;
import ballerina/log;

@http:ServiceConfig {
    basePath: "/pinevalley/categories"
}
service PineValleyHospitalService on httpListener {

    daos:Doctor doctor1 = {
        name: "seth mears",
        hospital: "pine valley community hospital",
        category: "surgery",
        availability: "3.00 p.m - 5.00 p.m",
        fee: 8000
    };

    daos:Doctor doctor2 = {
        name: "emeline fulton",
        hospital: "pine valley community hospital",
        category: "cardiology",
        availability: "8.00 a.m - 10.00 a.m",
        fee: 4000
    };

    daos:HospitalDAO clemencyHospitalDao = {
        doctorsList: [doctor1, doctor2],
        categories: ["surgery", "cardiology", "gynaecology", "ent", "paediatric"],
        patientMap: {

        },
        patientRecordMap: {

        }
    };

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/{category}/reserve"
    }
    resource function reserveAppointment(http:Caller caller, http:Request req, string category) {
        reserveAppointment(caller, req, untaint self.clemencyHospitalDao, category);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}"
    }
    resource function getAppointment(http:Caller caller, http:Request req, int appointmentId) {
        getAppointment(caller, req, appointmentId);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}/fee"
    }
    resource function checkChannellingFee(http:Caller caller, http:Request req, int appointmentId) {
        checkChannellingFee(caller, req, appointmentId);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/patient/updaterecord"
    }
    resource function updatePatientRecord(http:Caller caller, http:Request req) {
        updatePatientRecord(caller, req, self.clemencyHospitalDao);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/patient/{ssn}/getrecord"
    }
    resource function getPatientRecord(http:Caller caller, http:Request req, string ssn) {
        getPatientRecord(caller, req, self.clemencyHospitalDao, ssn);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/patient/appointment/{appointmentId}/discount"
    }
    resource function isEligibleForDiscount(http:Caller caller, http:Request req, int appointmentId) {
        isEligibleForDiscount(caller, req, appointmentId);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/admin/doctor/newdoctor"
    }
    resource function addNewDoctor(http:Caller caller, http:Request req) {
        addNewDoctor(caller, req, untaint self.clemencyHospitalDao);
    }
}









