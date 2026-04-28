using System;
using BCrypt.Net;

public class Hasher {
    public static void Main() {
        Console.WriteLine("Qc@123456:" + BCrypt.Net.BCrypt.HashPassword("Qc@123456"));
        Console.WriteLine("Op@123456:" + BCrypt.Net.BCrypt.HashPassword("Op@123456"));
        Console.WriteLine("Admin@123:" + BCrypt.Net.BCrypt.HashPassword("Admin@123"));
    }
}
