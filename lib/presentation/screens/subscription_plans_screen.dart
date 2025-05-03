import 'package:flutter/material.dart';
import 'package:oposiwork/app/theme/app_theme.dart';
import 'package:oposiwork/presentation/widgets/custom_button.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  int _selectedPlanIndex = 1; // Por defecto, seleccionamos el plan mensual

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes Premium'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            const Text(
              'Desbloquea todo el contenido',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Accede a todos los temarios, ejercicios y recursos exclusivos para preparar tus oposiciones.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Planes de suscripción
            _buildSubscriptionPlan(
              index: 0,
              title: 'Pago único',
              price: '17,00 €',
              description: 'Acceso a todos los temarios y funciones extra.',
              features: [
                'Acceso a todos los temarios',
                'Descarga de PDFs',
                'Sin renovación automática',
                'Acceso permanente',
              ],
              isPopular: false,
            ),
            _buildSubscriptionPlan(
              index: 1,
              title: 'Mensual',
              price: '4,49 €/mes',
              description: 'Acceso completo, actualizaciones y alertas exclusivas.',
              features: [
                'Acceso a todos los temarios',
                'Descarga de PDFs',
                'Actualizaciones de temarios',
                'Alertas exclusivas',
                'Cancelación en cualquier momento',
              ],
              isPopular: true,
            ),
            _buildSubscriptionPlan(
              index: 2,
              title: 'Anual',
              price: '34,99 €/año',
              description: 'Precio ideal para fidelizar y asegurar ingresos.',
              features: [
                'Acceso a todos los temarios',
                'Descarga de PDFs',
                'Actualizaciones de temarios',
                'Alertas exclusivas',
                'Ahorro de 18,89 € respecto al plan mensual',
                'Cancelación en cualquier momento',
              ],
              isPopular: false,
            ),
            const SizedBox(height: 24),

            // Botón de suscripción
            CustomButton(
              text: 'Suscribirme ahora',
              onPressed: () {
                _processPurchase();
              },
            ),
            const SizedBox(height: 16),

            // Texto legal
            const Text(
              'Al suscribirte, aceptas nuestros Términos y Condiciones y Política de Privacidad. Puedes cancelar tu suscripción en cualquier momento desde la configuración de tu cuenta.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Preguntas frecuentes
            const Text(
              'Preguntas frecuentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              question: '¿Cómo puedo cancelar mi suscripción?',
              answer: 'Puedes cancelar tu suscripción en cualquier momento desde la sección "Mi cuenta" en la aplicación. La cancelación será efectiva al final del período de facturación actual.',
            ),
            _buildFaqItem(
              question: '¿Qué métodos de pago aceptan?',
              answer: 'Aceptamos tarjetas de crédito/débito (Visa, Mastercard, American Express) y PayPal.',
            ),
            _buildFaqItem(
              question: '¿Puedo cambiar de plan?',
              answer: 'Sí, puedes cambiar entre los planes mensual y anual en cualquier momento. El cambio será efectivo en tu próximo ciclo de facturación.',
            ),
            _buildFaqItem(
              question: '¿Ofrecen reembolsos?',
              answer: 'Ofrecemos un período de garantía de devolución de 7 días para nuevas suscripciones. Contacta con nuestro servicio de atención al cliente para solicitar un reembolso.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlan({
    required int index,
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required bool isPopular,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Radio(
                        value: index,
                        groupValue: _selectedPlanIndex,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _selectedPlanIndex = value as int;
                          });
                        },
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 36.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...features.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.accentColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(feature),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.premiumColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'MÁS POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }

  void _processPurchase() {
    // En una implementación real, aquí se procesaría la compra
    // a través de la API de pagos (Google Play, App Store, etc.)
    
    // Por ahora, solo mostrar un diálogo de confirmación
    String planName;
    String price;
    
    switch (_selectedPlanIndex) {
      case 0:
        planName = 'Pago único';
        price = '17,00 €';
        break;
      case 1:
        planName = 'Mensual';
        price = '4,49 €/mes';
        break;
      case 2:
        planName = 'Anual';
        price = '34,99 €/año';
        break;
      default:
        planName = 'Desconocido';
        price = '0,00 €';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar suscripción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan seleccionado: $planName'),
            Text('Precio: $price'),
            const SizedBox(height: 16),
            const Text(
              'En una aplicación real, aquí se procesaría el pago a través de la plataforma correspondiente (Google Play o App Store).',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simular éxito en la suscripción
              _showSuccessDialog();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Suscripción exitosa!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              '¡Gracias por suscribirte a Oposiwork Premium!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Ahora tienes acceso a todos los temarios y funcionalidades premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Comenzar a explorar'),
          ),
        ],
      ),
    );
  }
}
