package com.nkming.nc_photos

import android.content.Context
import android.util.Pair
import com.nkming.nc_photos.np_android_log.logE
import com.nkming.nc_photos.np_android_log.logI
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.security.cert.Certificate
import java.security.cert.CertificateFactory
import java.time.OffsetDateTime

// Modifications to this class must also reflect on dart side
data class CertInfo(
	val host: String, val sha1: String, val subject: String,
	val issuer: String, val startValidity: OffsetDateTime,
	val endValidity: OffsetDateTime
) {
	companion object {
		fun fromJson(json: JSONObject): CertInfo {
			return CertInfo(
				json.getString("host"), json.getString("sha1"),
				json.getString("subject"), json.getString("issuer"),
				OffsetDateTime.parse(json.getString("startValidity")),
				OffsetDateTime.parse(json.getString("endValidity"))
			)
		}
	}
}

class SelfSignedCertManager {
	/**
	 * Read and return all persisted certificates
	 *
	 * @return List of certificates with the corresponding info
	 */
	fun readAllCerts(context: Context): List<Pair<CertInfo, Certificate>> {
		val products = ArrayList<Pair<CertInfo, Certificate>>()
		val certDir = openCertsDir(context)
		val certFiles = certDir.listFiles()!!
		val factory = CertificateFactory.getInstance("X.509")
		for (f in certFiles) {
			if (f.name.endsWith(".json")) {
				// companion file
				continue
			}
			try {
				val c = factory.generateCertificate(FileInputStream(f))
				val jsonFile = File(certDir, f.name + ".json")
				val jsonStr = jsonFile.bufferedReader().use { it.readText() }
				val info = CertInfo.fromJson(JSONObject(jsonStr))
				logI(
					"SelfSignedCertManager::readAllCerts",
					"Found certificate: ${f.name} for host: ${info.host}"
				)
				products.add(Pair(info, c))
			} catch (e: Exception) {
				logE(
					"SelfSignedCertManager::readAllCerts",
					"Failed to read certificate file: ${f.name}", e
				)
			}
		}
		return products
	}

//	Outdated, don't use
//	/**
//	 * Persist a new PEM cert for a host
//	 */
//	fun writeCert(context: Context, hostName: String, pemCert: String) {
//		val certDir = openCertsDir(context)
//		while (true) {
//			val certF = File(certDir, UUID.randomUUID().toString())
//			if (certF.exists()) {
//				continue
//			}
//			FileWriter(certF).use {
//				it.write(pemCert)
//			}
//
//			val siteF = File(certDir, certF.name + ".site")
//			FileWriter(siteF).use {
//				it.write(hostName)
//			}
//			return
//		}
//	}

	private fun openCertsDir(context: Context): File {
		val certDir = File(context.filesDir, "certs")
		return if (!certDir.exists()) {
			certDir.mkdir()
			certDir
		} else if (!certDir.isDirectory) {
			logE(
				"SelfSignedCertManager::openCertsDir",
				"Removing certs file to make way for the directory"
			)
			certDir.delete()
			certDir.mkdir()
			certDir
		} else {
			certDir
		}
	}
}
