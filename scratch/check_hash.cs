using System;
using BCrypt.Net;

class Program {
    static void Main() {
        string password = "Qc@123456";
        string hash = "$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK";
        bool matches = BCrypt.Net.BCrypt.Verify(password, hash);
        Console.WriteLine($"Password: {password}");
        Console.WriteLine($"Hash: {hash}");
        Console.WriteLine($"Matches: {matches}");
    }
}
