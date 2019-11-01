Feature: Better user counting

    # until rhel has PR: https://github.com/rpm-software-management/libdnf/pull/807
    @not.with_os=rhel__eq__8
    @destructive
    @fixture.httpd
    Scenario: User-Agent header is sent
        Given I am running a system identified as the "Fedora 30 server"
          And I use repository "dnf-ci-fedora" as http
          And I start capturing outbound HTTP requests
         When I execute dnf with args "makecache"
         Then every HTTP GET request should match:
            | header     | value                                    |
            | User-Agent | libdnf (Fedora 30; server; Linux.x86_64) |

    @not.with_os=rhel__eq__8
    @destructive
    @fixture.httpd
    Scenario: User-Agent header is sent (missing variant)
        Given I am running a system identified as the "Fedora 31"
          And I use repository "dnf-ci-fedora" as http
          And I start capturing outbound HTTP requests
         When I execute dnf with args "makecache"
         Then every HTTP GET request should match:
            | header     | value                                     |
            | User-Agent | libdnf (Fedora 31; generic; Linux.x86_64) |

    @not.with_os=rhel__eq__8
    @destructive
    @fixture.httpd
    Scenario: User-Agent header is sent (unknown variant)
        Given I am running a system identified as the "Fedora 31 myspin"
          And I use repository "dnf-ci-fedora" as http
          And I start capturing outbound HTTP requests
         When I execute dnf with args "makecache"
         Then every HTTP GET request should match:
            | header     | value                                     |
            | User-Agent | libdnf (Fedora 31; generic; Linux.x86_64) |

    @not.with_os=rhel__eq__8
    @destructive
    @fixture.httpd
    Scenario: Shortened User-Agent value on a non-Fedora system
        Given I am running a system identified as the "OpenSUSE 15.1 desktop"
          And I use repository "dnf-ci-fedora" as http
          And I start capturing outbound HTTP requests
         When I execute dnf with args "makecache"
         Then every HTTP GET request should match:
            | header     | value  |
            | User-Agent | libdnf |

    @not.with_os=rhel__eq__8
    @destructive
    @fixture.httpd
    Scenario: No os-release file installed
        Given I remove the os-release file
          And I use repository "dnf-ci-fedora" as http
          And I start capturing outbound HTTP requests
         When I execute dnf with args "makecache"
         Then the exit code is 0
          And every HTTP GET request should match:
            | header     | value  |
            | User-Agent | libdnf |

    @fixture.httpd
    Scenario: Custom User-Agent value
        Given I use repository "dnf-ci-fedora" as http
          And I set config option "user_agent" to "'Agent 007'"
          And I start capturing outbound HTTP requests
         When I execute dnf with args "makecache"
         Then every HTTP GET request should match:
            | header     | value     |
            | User-Agent | Agent 007 |

    @not.with_os=rhel__eq__8
    @fixture.httpd
    Scenario: Countme flag is sent once per week
        Given I set config option "countme" to "1"
          And today is Wednesday, August 07, 2019
          And I copy repository "dnf-ci-fedora" for modification
          And I use repository "dnf-ci-fedora" as http
          And I set up metalink for repository "dnf-ci-fedora"
          And I start capturing outbound HTTP requests
         # First week (bucket 1)
         # Note: One in the first 4 requests is randomly chosen to include the
         # flag (see COUNTME_BUDGET=4 in libdnf/repo/Repo.cpp for details)
         When I execute dnf with args "makecache" 4 times
         Then exactly one HTTP GET request should match:
            | path                     |
            | */metalink.xml?countme=1 |
         # Same week (should not be sent)
         When today is Friday, August 09, 2019
          And I forget any HTTP requests captured so far
          And I execute dnf with args "makecache" 4 times
         Then no HTTP GET request should match:
            | path                     |
            | */metalink.xml?countme=* |
         # Next week (bucket 1)
         When today is Tuesday, August 13, 2019
          And I forget any HTTP requests captured so far
          And I execute dnf with args "makecache" 4 times
         Then exactly one HTTP GET request should match:
            | path                     |
            | */metalink.xml?countme=1 |
         # Next week (bucket 2)
         When today is Tuesday, August 21, 2019
          And I forget any HTTP requests captured so far
          And I execute dnf with args "makecache" 4 times
         Then exactly one HTTP GET request should match:
            | path                     |
            | */metalink.xml?countme=2 |
         # 1 month later (bucket 3)
         When today is Tuesday, September 16, 2019
          And I forget any HTTP requests captured so far
          And I execute dnf with args "makecache" 4 times
         Then exactly one HTTP GET request should match:
            | path                     |
            | */metalink.xml?countme=3 |
         # 6 months later (bucket 4)
         When today is Tuesday, March 15, 2020
          And I forget any HTTP requests captured so far
          And I execute dnf with args "makecache" 4 times
         Then exactly one HTTP GET request should match:
            | path                     |
            | */metalink.xml?countme=4 |

    @not.with_os=rhel__eq__8
    @fixture.httpd
    Scenario: Countme flag is not sent repeatedly on retries
        Given I set config option "countme" to "1"
          And I copy repository "dnf-ci-fedora" for modification
          And I use repository "dnf-ci-fedora" as http
          And I set up metalink for repository "dnf-ci-fedora"
          # This triggers the retry mechanism in librepo, 4 retries by default
          And the server starts responding with HTTP status code 503
          And I start capturing outbound HTTP requests
         When I execute dnf with args "makecache" 4 times
         # 48 = 4 * makecache = 4 * (3 metalink attempts * 4 low-level retries)
         # See librepo commits 15adfb31 and 12d0b4ad for details
         Then exactly 48 HTTP GET requests should match:
            | path            |
            | */metalink.xml* |
          And exactly one HTTP GET request should match:
            | path                     |
            | */metalink.xml?countme=1 |

    @fixture.httpd
    Scenario: Countme feature is disabled
        Given I set config option "countme" to "0"
          And I copy repository "dnf-ci-fedora" for modification
          And I use repository "dnf-ci-fedora" as http
          And I set up metalink for repository "dnf-ci-fedora"
          And I start capturing outbound HTTP requests
         When I execute dnf with args "makecache" 4 times
         Then no HTTP GET request should match:
            | path                     |
            | */metalink.xml?countme=1 |
