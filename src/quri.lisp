(in-package :cl-user)
(defpackage quri
  (:use :cl
        :quri.uri
        :quri.uri.ftp
        :quri.uri.http
        :quri.uri.ldap
        :quri.uri.file
        :quri.error)
  (:import-from :quri.domain
                :uri-tld
                :uri-domain
                :ipv4-addr-p
                :ipv6-addr-p
                :ip-addr-p
                :ip-addr=
                :cookie-domain-p)
  (:import-from :quri.parser
                :parse-uri
                :parse-scheme
                :parse-authority
                :parse-path
                :parse-query
                :parse-fragment)
  (:import-from :quri.decode
                :url-decode
                :url-decode-params)
  (:import-from :quri.encode
                :url-encode
                :url-encode-params)
  (:export :parse-uri
           :parse-scheme
           :parse-authority
           :parse-path
           :parse-query
           :parse-fragment

           :uri
           :uri=
           :uri-p
           :uri-scheme
           :uri-userinfo
           :uri-host
           :uri-port
           :uri-path
           :uri-query
           :uri-fragment
           :uri-authority

           :uri-tld
           :uri-domain
           :ipv4-addr-p
           :ipv6-addr-p
           :ip-addr-p
           :ip-addr=
           :cookie-domain-p

           :urn
           :urn-p
           :urn-nid
           :urn-nss

           :uri-ftp
           :uri-ftp-p
           :uri-ftp-typecode

           :uri-http
           :uri-http-p
           :uri-query-params

           :uri-ldap
           :uri-ldap-p
           :uri-ldap-dn
           :uri-ldap-attributes
           :uri-ldap-scope
           :uri-ldap-filter
           :uri-ldap-extensions

           :uri-file
           :uri-file-p
           :uri-file-pathname

           :copy-uri
           :render-uri

           :url-decode
           :url-decode-params
           :url-encode
           :url-encode-params

           :uri-error
           :uri-malformed-string
           :uri-invalid-port
           :url-decoding-error
           :uri-malformed-urlencoded-string))
(in-package :quri)

(defun scheme-constructor (scheme)
  "Get a constructor function appropriate for the scheme."
  (cond
    ((string= scheme "http")  #'make-uri-http)
    ((string= scheme "https") #'make-uri-https)
    ((string= scheme "ldap")  #'make-uri-ldap)
    ((string= scheme "ldaps") #'make-uri-ldaps)
    ((string= scheme "ftp")   #'make-uri-ftp)
    ((string= scheme "file")  #'make-uri-file)
    ((string= scheme "urn")   #'make-urn)
    (T                        #'make-uri)))

(defun uri (data &key (start 0) end)
  (if (uri-p data)
      data
      (multiple-value-bind (scheme userinfo host port path query fragment)
          (parse-uri data :start start :end end)
        (apply (scheme-constructor scheme)
               :scheme scheme
               :userinfo userinfo
               :host host
               :path path
               :query query
               :fragment fragment

               (and port
                    `(:port ,port))))))

(defun copy-uri (uri &key
                       (scheme (uri-scheme uri))
                       (userinfo (uri-userinfo uri))
                       (host (uri-host uri))
                       (port (uri-port uri))
                       (path (uri-path uri))
                       (query (uri-query uri))
                       (fragment (uri-fragment uri)))
  (funcall (scheme-constructor scheme)
           :scheme scheme
           :userinfo userinfo
           :host host
           :port port
           :path path
           :query query
           :fragment fragment))

(defun render-uri (uri &optional stream)
  (cond
    ((uri-ftp-p uri)
     (format stream
             "~@[~(~A~):~]~@[//~(~A~)~]~@[~A~]~@[;type=~A~]~@[?~A~]~@[#~A~]"
             (uri-scheme uri)
             (uri-authority uri)
             (uri-path uri)
             (uri-ftp-typecode uri)
             (uri-query uri)
             (uri-fragment uri)))
    ((uri-file-p uri)
     (format stream
             "~@[~(~A~)://~]~@[~(~a~)~]"
             (uri-scheme uri)
             (uri-path uri)))
    (T
     (format stream
             "~@[~(~A~):~]~@[//~(~A~)~]~@[~A~]~@[?~A~]~@[#~A~]"
             (uri-scheme uri)
             (uri-authority uri)
             (uri-path uri)
             (uri-query uri)
             (uri-fragment uri)))))

(defun uri= (uri1 uri2)
  (check-type uri1 uri)
  (check-type uri2 uri)
  (when (eq (type-of uri1) (type-of uri2))
    (and (eq    (uri-scheme uri1)    (uri-scheme uri2))
         (equal (uri-path uri1)      (uri-path uri2))
         (equal (uri-query uri1)     (uri-query uri2))
         (equal (uri-fragment uri1)  (uri-fragment uri2))
         (equalp (uri-authority uri1) (uri-authority uri2))
         (or (not (uri-ftp-p uri1))
             (eql (uri-ftp-typecode uri1) (uri-ftp-typecode uri2))))))

(defmethod print-object ((uri uri) stream)
  (format stream "#<~S ~A>"
          (type-of uri)
          (render-uri uri)))
