using System;
using BCrypt.Net;

class Program {
    static void Main() {
        string password = "Qc@123456";
        string hash = BCrypt.Net.BCrypt.HashPassword(password);
        Console.WriteLine(hash);
    }
}
