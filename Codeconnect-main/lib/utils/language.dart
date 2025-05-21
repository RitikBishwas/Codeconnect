import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';

class Language {
  const Language(
      this.name, this.code, this.lang, this.defaultCode, this.appendCode);
  final String name;
  final Mode code;
  final String lang;
  final String defaultCode;
  final String appendCode;
}

class LanguageTemplate {
  static final Map<String, Language> templates = {
    'C++': Language('C++', cpp, 'cpp', '''
#include <bits/stdc++.h>
using namespace std;

void solution() {
    // Write you code here
    cout<< "Hello World";
}
''', '''
int main() {
    auto start = chrono::high_resolution_clock::now();
    solution();
    auto stop = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<chrono::milliseconds>(stop - start).count();
    cout << "\\n" << duration;
    return 0;
}
'''),
    'Python': Language('Python', python, 'python', '''
import time

def solution():
    # Write your code here
    print("Hello World")
''', '''
if __name__ == "__main__":
    start = time.perf_counter()
    solution()
    stop = time.perf_counter()
    duration = (stop - start) * 1_000
    print(f"\\n{int(duration)}")
'''),
//     'Java': Language('Java', java, 'java', '''
// import java.io.*;
// import java.util.*;

// class Solution {
//     public static void solution() {
//       // Write your code here
//       System.out.println("Hello World");
//     }
// }
// ''', '''
// public class Main {
//     public static void main(String[] args) {
//         long start = System.nanoTime();
//         Solution.solution();
//         long stop = System.nanoTime();
//         long duration = (stop - start) / 1000000;
//         System.out.println("\\n" + duration);
//     }
// }
// '''),
    'JavaScript': Language('JavaScript', javascript, 'javascript', '''
function solution() {
    // Write your code here
    console.log("Hello World");
}
''', '''
function main() {
    const start = Date.now();
    solution();
    const stop = Date.now();
    const duration = stop - start;
    console.log("\\n" + duration);
}

main();
''')
  };

  static List<String> getLanguages() {
    return templates.keys.toList();
  }

  // Get template for "cpp", "java", "python", or "javascript" language
  static Language getTemplate(String language) {
    return templates[language] ?? templates['C++']!;
  }
}
